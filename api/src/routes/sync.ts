// Sync routes — CRDT changeset exchange for offline-first sync
import { Hono } from 'hono';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();
const app = new Hono();

// ─── GET /sync/status ──────────────────────────────────────────────────────
app.get('/status', async (c) => {
  const teamId = c.get('teamId');
  if (!teamId) return c.json({ error: 'teamId required' }, 400);

  const [lastItem, lastLocation, lastItemLocation] = await Promise.all([
    prisma.item.findFirst({ where: { teamId }, orderBy: { updatedAt: 'desc' }, select: { updatedAt: true } }),
    prisma.location.findFirst({ where: { teamId }, orderBy: { updatedAt: 'desc' }, select: { updatedAt: true } }),
    prisma.itemLocation.findFirst({ orderBy: { timestamp: 'desc' }, select: { timestamp: true } }),
  ]);

  return c.json({
    lastSync: [lastItem?.updatedAt, lastLocation?.updatedAt, lastItemLocation?.timestamp]
      .filter(Boolean)
      .sort()
      .pop() || null,
  });
});

// ─── GET /sync/changes ─────────────────────────────────────────────────────
// Returns all changes since a given timestamp for the team
app.get('/changes', async (c) => {
  const teamId = c.get('teamId');
  if (!teamId) return c.json({ error: 'teamId required' }, 400);

  const since = c.req.query('since'); // ISO timestamp

  const itemWhere = { teamId, ...(since ? { updatedAt: { gt: new Date(since) } } : {}) };
  const locationWhere = { teamId, ...(since ? { updatedAt: { gt: new Date(since) } } : {}) };
  const itemLocationWhere = {
    item: { teamId },
    ...(since ? { timestamp: { gt: new Date(since) } } : {}),
  };

  const [items, locations, itemLocations] = await Promise.all([
    prisma.item.findMany({ where: itemWhere }),
    prisma.location.findMany({ where: locationWhere }),
    prisma.itemLocation.findMany({ where: itemLocationWhere }),
  ]);

  return c.json({
    changeset: { items, locations, itemLocations },
    serverTimestamp: new Date().toISOString(),
  });
});

// ─── POST /sync/push ──────────────────────────────────────────────────────
// Accept changes from a client (CRDT merge: upsert by ID, last-write-wins)
app.post('/push', async (c) => {
  const teamId = c.get('teamId');
  if (!teamId) return c.json({ error: 'teamId required' }, 400);

  const body = await c.req.json();
  const { items = [], locations = [], itemLocations = [] } = body;

  const results = { items: 0, locations: 0, itemLocations: 0 };

  // Upsert items
  for (const item of items) {
    await prisma.item.upsert({
      where: { id: item.id },
      update: {
        name: item.name,
        details: item.details,
        customFields: item.customFields ?? {},
        isDeleted: item.isDeleted ?? false,
        updatedAt: new Date(item.updatedAt),
      },
      create: {
        id: item.id,
        name: item.name,
        details: item.details ?? '',
        customFields: item.customFields ?? {},
        qrCodeData: item.qrCodeData ?? `stokedrift://item/${item.id}`,
        teamId,
        isDeleted: item.isDeleted ?? false,
        createdAt: new Date(item.createdAt),
        updatedAt: new Date(item.updatedAt),
      },
    });
    results.items++;
  }

  // Upsert locations
  for (const loc of locations) {
    await prisma.location.upsert({
      where: { id: loc.id },
      update: {
        name: loc.name,
        latitude: loc.latitude,
        longitude: loc.longitude,
        radius: loc.radius,
        address: loc.address,
        isDeleted: loc.isDeleted ?? false,
        updatedAt: new Date(loc.updatedAt),
      },
      create: {
        id: loc.id,
        name: loc.name,
        latitude: loc.latitude,
        longitude: loc.longitude,
        radius: loc.radius ?? 50,
        address: loc.address ?? '',
        teamId,
        isDeleted: loc.isDeleted ?? false,
        createdAt: new Date(loc.createdAt),
        updatedAt: new Date(loc.updatedAt),
      },
    });
    results.locations++;
  }

  // Upsert item locations
  for (const il of itemLocations) {
    await prisma.itemLocation.upsert({
      where: { id: il.id },
      update: {
        latitude: il.latitude,
        longitude: il.longitude,
        address: il.address,
        notes: il.notes,
        isDeleted: il.isDeleted ?? false,
        timestamp: new Date(il.timestamp),
      },
      create: {
        id: il.id,
        itemId: il.itemId,
        locationId: il.locationId,
        latitude: il.latitude,
        longitude: il.longitude,
        address: il.address ?? '',
        notes: il.notes ?? '',
        isDeleted: il.isDeleted ?? false,
        timestamp: new Date(il.timestamp),
      },
    });
    results.itemLocations++;
  }

  // Return current server state since the client's last sync
  const serverTimestamp = new Date().toISOString();
  return c.json({ results, serverTimestamp });
});

export default app;