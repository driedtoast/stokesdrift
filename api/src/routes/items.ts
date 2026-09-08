// Item routes — CRUD for items within a team context
import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { PrismaClient } from '@prisma/client';
import { v4 as uuid } from 'uuid';

const prisma = new PrismaClient();
const app = new Hono();

const createItemSchema = z.object({
  name: z.string().min(1).max(200),
  details: z.string().max(2000).default(''),
  customFields: z.record(z.string()).default({}),
});

const updateItemSchema = z.object({
  name: z.string().min(1).max(200).optional(),
  details: z.string().max(2000).optional(),
  customFields: z.record(z.string()).optional(),
});

// ─── GET /items ────────────────────────────────────────────────────────────
app.get('/', async (c) => {
  const teamId = c.get('teamId');
  if (!teamId) return c.json({ error: 'teamId query param or X-Team-Id header required' }, 400);

  const items = await prisma.item.findMany({
    where: { teamId, isDeleted: false },
    orderBy: { updatedAt: 'desc' },
  });

  return c.json({ items });
});

// ─── POST /items ───────────────────────────────────────────────────────────
app.post('/', zValidator('json', createItemSchema), async (c) => {
  const teamId = c.get('teamId');
  if (!teamId) return c.json({ error: 'teamId required' }, 400);

  const { name, details, customFields } = c.req.valid('json');
  const id = uuid();
  const qrCodeData = `stokedrift://item/${id}`;

  const item = await prisma.item.create({
    data: {
      id,
      name,
      details,
      customFields,
      qrCodeData,
      teamId,
    },
  });

  return c.json({ item }, 201);
});

// ─── GET /items/:id ────────────────────────────────────────────────────────
app.get('/:id', async (c) => {
  const teamId = c.get('teamId');
  const item = await prisma.item.findFirst({
    where: { id: c.req.param('id'), teamId, isDeleted: false },
    include: { locations: { where: { isDeleted: false }, orderBy: { timestamp: 'desc' } } },
  });

  if (!item) return c.json({ error: 'Item not found' }, 404);
  return c.json({ item });
});

// ─── PUT /items/:id ────────────────────────────────────────────────────────
app.put('/:id', zValidator('json', updateItemSchema), async (c) => {
  const teamId = c.get('teamId');
  const id = c.req.param('id');
  const data = c.req.valid('json');

  const existing = await prisma.item.findFirst({ where: { id, teamId, isDeleted: false } });
  if (!existing) return c.json({ error: 'Item not found' }, 404);

  const item = await prisma.item.update({
    where: { id },
    data,
  });

  return c.json({ item });
});

// ─── DELETE /items/:id ──────────────────────────────────────────────────────
app.delete('/:id', async (c) => {
  const teamId = c.get('teamId');
  const id = c.req.param('id');

  const existing = await prisma.item.findFirst({ where: { id, teamId, isDeleted: false } });
  if (!existing) return c.json({ error: 'Item not found' }, 404);

  // Soft delete
  await prisma.item.update({ where: { id }, data: { isDeleted: true } });
  await prisma.itemLocation.updateMany({ where: { itemId: id }, data: { isDeleted: true } });

  return c.json({ success: true });
});

// ─── POST /items/:id/mark-location ─────────────────────────────────────────
app.post('/:id/mark-location', async (c) => {
  const teamId = c.get('teamId');
  const itemId = c.req.param('id');

  const body = await c.req.json();
  const { latitude, longitude, address, notes, locationId } = body;

  const existing = await prisma.item.findFirst({ where: { id: itemId, teamId, isDeleted: false } });
  if (!existing) return c.json({ error: 'Item not found' }, 404);

  // Auto-match location by proximity
  let resolvedLocationId = locationId;
  if (!resolvedLocationId && latitude && longitude) {
    const locations = await prisma.location.findMany({ where: { teamId, isDeleted: false } });
    for (const loc of locations) {
      if (loc.latitude && loc.longitude) {
        const dist = distanceInMeters(latitude, longitude, loc.latitude, loc.longitude);
        if (dist <= loc.radius) {
          resolvedLocationId = loc.id;
          break;
        }
      }
    }
  }

  const itemLocation = await prisma.itemLocation.create({
    data: {
      itemId,
      locationId: resolvedLocationId,
      latitude: latitude ?? null,
      longitude: longitude ?? null,
      address: address ?? '',
      notes: notes ?? '',
    },
  });

  return c.json({ itemLocation }, 201);
});

// ─── POST /items/:id/set-address ───────────────────────────────────────────
app.post('/:id/set-address', async (c) => {
  const teamId = c.get('teamId');
  const itemId = c.req.param('id');

  const { address, notes } = await c.req.json();

  const existing = await prisma.item.findFirst({ where: { id: itemId, teamId, isDeleted: false } });
  if (!existing) return c.json({ error: 'Item not found' }, 404);

  const itemLocation = await prisma.itemLocation.create({
    data: {
      itemId,
      address: address ?? '',
      notes: notes ?? '',
    },
  });

  return c.json({ itemLocation }, 201);
});

// ─── Utility ────────────────────────────────────────────────────────────────
function distanceInMeters(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371000;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) *
    Math.sin(dLon / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

export default app;