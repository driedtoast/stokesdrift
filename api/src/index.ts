// StokeDrift API — Hono Entry Point
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { prettyJSON } from 'hono/pretty-json';
import authRoutes from './routes/auth.js';
import itemRoutes from './routes/items.js';
import locationRoutes from './routes/locations.js';
import syncRoutes from './routes/sync.js';
import { authMiddleware } from './middleware/auth.js';

const app = new Hono();

// ─── Global middleware ───────────────────────────────────────────────────────
app.use('*', logger());
app.use('*', cors({ origin: '*', allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'] }));
app.use('*', prettyJSON());

// ─── Health check ────────────────────────────────────────────────────────────
app.get('/', (c) => c.json({ name: 'StokeDrift API', version: '0.1.0', status: 'ok' }));

// ─── Public routes ───────────────────────────────────────────────────────────
app.route('/auth', authRoutes);

// ─── Protected routes ────────────────────────────────────────────────────────
app.use('/items/*', authMiddleware);
app.use('/locations/*', authMiddleware);
app.use('/sync/*', authMiddleware);

app.route('/items', itemRoutes);
app.route('/locations', locationRoutes);
app.route('/sync', syncRoutes);

export default app;