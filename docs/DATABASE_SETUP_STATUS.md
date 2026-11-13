# Jumjum V5 — Database Setup Status

Updated: 13 November 2026

## Confirmed infrastructure
- Repository: `famoelwan/gomgomgames`, branch `main`.
- Hosting: Cloudflare Pages.
- Existing D1 database: `jumjumgames`.
- D1 ID: `8f6841a6-9548-4302-89db-47599721c192`.
- Pages D1 binding: `DB`.

## Selected architecture
- Cloudflare D1 remains for existing game categories, settings, stage configuration and operational data.
- Turso Free replaces Supabase for player, family, child, progress and protected account records.
- Firebase Authentication is for sign-in/identity only. Server-side Pages Functions verify Firebase ID tokens before database access.
- Servimg and FAMO-PIC are temporary external image hosts; database stores image URLs/metadata only.
- Cloudflare R2 is not used because it requires a payment card in the user's current setup.

## Confirmed D1 state
- Migrations 0001 and 0002 applied successfully via GitHub Actions run `43343462323`.
- 36 categories verified (12 general, 8 babys, 8 kids, 8 juniors).
- 15 game settings verified.
- D1 Free allowance is 5 GB total per account, up to 10 databases, with a 500 MB maximum per database.

## Turso status
- Free plan currently lists 5 GB storage, 100 databases, 500 million rows read/month and 10 million rows written/month; no credit card required to start.
- Schema prepared at `turso/migrations/0001_player_family_progress.sql`.
- Turso database and credentials are not yet created/configured.
- Do not place Turso auth tokens in Git, browser code, screenshots or chat. Store them only as Cloudflare server-side secrets.

## Supabase disposition
- User reported Supabase SQL Editor returned `Success. No rows returned`; it may have created the 12 planned tables.
- Supabase tables/RLS were not independently verified.
- Supabase files were removed from current Git tree prematurely; this was an implementation mistake. They remain recoverable from Git history.
- Do not delete the Supabase project or tables until confirming no data/dependency exists and exporting anything needed.

## Product data decisions
- Launch question bank target: 76,000 (60,000 adult/13+, 16,000 children).
- 200 Adventure stages; operational stage distribution sums to 8,080 questions. Stage rows remain unseeded pending review.
- No question content is inserted by migrations 0001/0002 or the Turso player schema.
