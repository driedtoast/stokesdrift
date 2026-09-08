# stokesdrift API

Hono-based REST API for stokesdrift asset tracking.

## Tech Stack
- **Hono** — fast web framework
- **Prisma** — ORM for PostgreSQL
- **Zod** — request validation
- **JWT** — authentication

## Setup

```bash
# Install dependencies
npm install

# Set up database URL
export DATABASE_URL="postgresql://user:password@localhost:5432/stokedrift"

# Run migrations
npm run db:migrate:dev

# Start dev server
npm run dev
```

## API Endpoints

### Auth
- `POST /auth/register` — Create account
- `POST /auth/login` — Login
- `GET /auth/me` — Get current user

### Items (require auth + teamId)
- `GET /items?teamId=xxx` — List items
- `POST /items` — Create item
- `GET /items/:id` — Get item with location history
- `PUT /items/:id` — Update item
- `DELETE /items/:id` — Soft-delete item
- `POST /items/:id/mark-location` — Record GPS scan
- `POST /items/:id/set-address` — Record address

### Locations (require auth + teamId)
- `GET /locations?teamId=xxx` — List locations
- `POST /locations` — Create location
- `GET /locations/:id` — Get location with items
- `PUT /locations/:id` — Update location
- `DELETE /locations/:id` — Soft-delete location

### Sync (require auth + teamId)
- `GET /sync/status` — Get last sync timestamp
- `GET /sync/changes?since=ISO_TIMESTAMP` — Pull changes since timestamp
- `POST /sync/push` — Push local changes to server