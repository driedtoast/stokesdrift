// Auth routes — register, login, refresh, me
import { Hono } from 'hono';
import { sign } from 'hono/jwt';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();
const app = new Hono();

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-me';

const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  name: z.string().min(1).max(100),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string(),
});

// ─── POST /auth/register ──────────────────────────────────────────────────
app.post('/register', zValidator('json', registerSchema), async (c) => {
  const { email, password, name } = c.req.valid('json');

  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    return c.json({ error: 'Email already registered' }, 409);
  }

  const hashed = await bcrypt.hash(password, 10);
  const user = await prisma.user.create({
    data: { email, name, password: hashed },
  });

  // Auto-create a personal team
  const team = await prisma.team.create({
    data: { name: `${name}'s Team`, ownerId: user.id },
  });
  await prisma.teamMember.create({
    data: { userId: user.id, teamId: team.id, role: 'OWNER' },
  });

  const token = await sign({ sub: user.id, teamId: team.id, exp: Math.floor(Date.now() / 1000) + 60 * 60 * 24 }, JWT_SECRET);

  return c.json({ token, user: { id: user.id, email: user.email, name: user.name }, teamId: team.id }, 201);
});

// ─── POST /auth/login ─────────────────────────────────────────────────────
app.post('/login', zValidator('json', loginSchema), async (c) => {
  const { email, password } = c.req.valid('json');

  const user = await prisma.user.findUnique({
    where: { email },
    include: { memberships: { include: { team: true } } },
  });

  if (!user) {
    return c.json({ error: 'Invalid credentials' }, 401);
  }

  const valid = await bcrypt.compare(password, user.password);
  if (!valid) {
    return c.json({ error: 'Invalid credentials' }, 401);
  }

  const primaryTeam = user.memberships[0]?.teamId;
  const token = await sign({ sub: user.id, teamId: primaryTeam, exp: Math.floor(Date.now() / 1000) + 60 * 60 * 24 }, JWT_SECRET);

  return c.json({
    token,
    user: { id: user.id, email: user.email, name: user.name },
    teams: user.memberships.map((m) => ({ id: m.teamId, name: m.team?.name, role: m.role })),
  });
});

// ─── GET /auth/me ─────────────────────────────────────────────────────────
app.get('/me', async (c) => {
  const authHeader = c.req.header('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return c.json({ error: 'Unauthorized' }, 401);
  }

  try {
    const { verify } = await import('hono/jwt');
    const payload = await verify(authHeader.slice(7), JWT_SECRET);
    const user = await prisma.user.findUnique({
      where: { id: payload.sub as string },
      include: { memberships: { include: { team: true } } },
    });

    if (!user) return c.json({ error: 'User not found' }, 404);

    return c.json({
      id: user.id,
      email: user.email,
      name: user.name,
      teams: user.memberships.map((m) => ({ id: m.teamId, name: m.team?.name, role: m.role })),
    });
  } catch {
    return c.json({ error: 'Invalid token' }, 401);
  }
});

export default app;