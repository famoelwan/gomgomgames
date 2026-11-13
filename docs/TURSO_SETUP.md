# Jumjum V5 — Turso setup

Turso Free currently advertises 5 GB storage, up to 100 databases, 500 million rows read/month, 10 million rows written/month, and no credit card required to start. Confirm the live pricing page before signup: https://turso.tech/pricing

## Purpose
Turso replaces Supabase for player and family data. Existing Cloudflare D1 remains in place for game catalog, categories, settings and stage configuration.

## Setup sequence
1. Create a Turso account using its free signup flow.
2. Create one database for Jumjum player/family data in a region suitable for the game's users.
3. Apply `turso/migrations/0001_player_family_progress.sql` to that database.
4. Create a database auth token in Turso.
5. Add the token only as a Cloudflare Pages server-side secret (never in frontend code, Git, screenshots or chat).
6. Configure the Cloudflare Pages Functions Turso connection using the official Cloudflare guide: https://developers.cloudflare.com/workers/databases/third-party-integrations/turso/
7. Implement server-side Firebase ID-token verification before any query.
8. Run owner-isolation and server-authoritative-write tests before connecting the live UI.

## Security
Turso does not provide Supabase-style row-level security policies. Every endpoint must authenticate the Firebase token, derive the UID from the verified token, and enforce owner checks in SQL. Keep age records, parent-consent writes, reward ledger, admin roles, device links and score updates server-only.

Never send database auth tokens, Firebase private keys or other secrets in chat.
