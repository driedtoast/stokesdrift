// Location routes — CRUD for locations within a team context
import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { PrismaClient } from '@prisma/client';
import { v4 as uuid } from 'uuid';

const prisma = new PrismaClient();
const app = new Hono();

const createLocationSchema = z.object({
  name: z.string().min(1).max(200),
  latitude: z.number().nullable().optional(),
  longitude: z.number().nullable().optional(),
  radius: z.number().default(50),
  address: z.string().default(''),
});

// ─── GET /locations ────────────────────────────────────────────────────────
app.get('/', async (c) => {
  const teamId = c.get('teamId');
  if (!teamId) return c.json({ error: 'teamId required' }, 400);

  const locations = await prisma.location.findMany({
    where: { teamId, isDeleted: false },
    orderBy: { name: 'asc' },
    include: {
      _count: { select: { items: { where: { isDeleted: false } } } },
    },
  });

  return c.json({
    locations: locations.map((l) => ({
      ...l,
      itemCount: l._count.items,
    })),
  });
});

// ─── POST /locations ───────────────────────────────────────────────────────
app.post('/', zValidator('json', createLocationSchema), async (c) => {
  const teamId = c.get('teamId');
  if (!teamId) return c.json({ error: 'teamId required' }, 400);

  const data = c.req.valid('json');

  const location = await prisma.location.create({
    data: {
      id: uuid(),
      ...data,
      teamId,
    },
  });

  return c.json({ location }, 201);
});

// ─── GET /locations/:id ─────────────────────────────────────────────────────
app.get('/:id', async (c) => {
  const teamId = c.get('teamId');
  const id = c.req.param('id');

  const location = await prisma.location.findFirst({
    where: { id, teamId, isDeleted: false },
    include: {
      items: {
        where: { isDeleted: false },
        include: { item: true },
        orderBy: { timestamp: 'desc' },
      },
    },
  });

  if (!location) return c.json({ error: 'Location not found' }, 404);

  // Deduplicate items at this location
  const seenItemIds = new Set<string>();
  const items = [];
  for (const il of location.items) {
    if (!seenItemIds.has(il.itemId)) {
      seenItemIds.add(il.itemId);
      items.push(il.item);
    }
  }

  return c.json({
    location: {
      id: location.id,
      name: location.name,
      latitude: location.latitude,
      longitude: location.longitude,
      radius: location.radius,
      address: location.address,
      createdAt: location.createdAt,
      updatedAt: location.updatedAt,
    },
    items,
  });
});

// ─── PUT /locations/:id ────────────────────────────────────────────────────
app.put('/:id', zValidator('json', createLocationSchema.partial()), async (c) => {
  const teamId = c.get('teamId');
  const id = c.req.param('id');

  const existing = await prisma.location.findFirst({ where: { id, teamId, isDeleted: false } });
  if (!existing) return c.json({ error: 'Location not found' }, 404);

  const data = c.req.valid('json');
  const location = await prisma.location.update({ where: { id }, data });

  return c.json({ location });
});

// ─── DELETE /locations/:id ─────────────────────────────────────────────────
app.delete('/:id', async (c) => {
  const teamId = c.get('teamId');
  const id = c.req.param('id');

  const existing = await prisma.location.findFirst({ where: { id, teamId, isDeleted: false } });
  if (!existing) return c.json({ error: 'Location not found' }, 404);

  // Soft delete
  await prisma.location.update({ where: { id }, data: { isDeleted: true } });

  return c.json({ success: true });
});

export default app;