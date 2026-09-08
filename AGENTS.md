# Agents

For business requirements look at ./REQUIREMENTS.md

For design style look at ./DESIGN.md

## Mobile

Mobile app is in ./mobile

Tech stack:
- flutter
- targeting ios and android
- sqlite_crdt for offline-first data
- geolocator for GPS
- mobile_scanner for QR code scanning
- share_plus for QR code sharing

Key screens:
- Home: dashboard with stats, recent items, locations
- Items: list with search, add/edit/delete
- Scan: QR scanner with GPS permission handling
- Locations: list with search, tap to see items at location
- Item Detail: QR code view/share, edit, GPS mark, address set, location history
- Location Detail: items at location, edit, delete

Database: sqlite_crdt with soft-delete, CRDT sync support (getChangeset/merge ready for API sync)

## App

Web management dashboard in ./app

Tech stack:
- preact
- vite build
- tailwind css 4
- preact signals for state

Features:
- Auth (login/signup)
- Item CRUD with custom fields
- Location CRUD with GPS zones
- Search/filter
- Team management via API
- Responsive design using Surf Daybreak design system

## Api

REST API in ./api

Tech stack:
- hono
- nodejs
- prisma for data management
- postgres
- JWT auth
- zod validation

Endpoints:
- Auth: register, login, me
- Items: CRUD + mark-location, set-address
- Locations: CRUD + items at location
- Sync: CRDT changeset exchange for offline-first mobile sync

## Site

Marketing landing page in ./site

Tech stack:
- hugo
- tailwind css

Static only site. Landing page with features, pricing, and CTA.