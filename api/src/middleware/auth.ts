// Auth middleware — validates JWT and attaches user to context
import { createMiddleware } from 'hono/factory';
import { verify } from 'hono/jwt';
import type { Context, Next } from 'hono';

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-me';

interface AuthEnv {
  Variables: {
    userId: string;
    teamId: string;
  };
}

export const authMiddleware = createMiddleware<AuthEnv>(async (c: Context, next: Next) => {
  const authHeader = c.req.header('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return c.json({ error: 'Unauthorized — missing token' }, 401);
  }

  const token = authHeader.slice(7);
  try {
    const payload = await verify(token, JWT_SECRET);
    c.set('userId', payload.sub as string);
    // teamId comes from query param or header for team-scoped operations
    const teamId = c.req.query('teamId') || c.req.header('X-Team-Id');
    if (teamId) {
      c.set('teamId', teamId);
    }
    await next();
  } catch {
    return c.json({ error: 'Unauthorized — invalid token' }, 401);
  }
});