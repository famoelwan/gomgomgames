# Jumjum V5 — Database Setup Status

Updated: 13 November 2026

## Confirmed infrastructure
- Git repository: `famoelwan/gomgomgames`, branch `main`.
- Hosting target: Cloudflare Pages.
- D1 database: `jumjumgames`.
- D1 database ID: `8f6841a6-9548-4302-89db-47599721c192`.
- Pages D1 binding: `DB`.
- Wrangler migration directory: `migrations`.

## Selected architecture
- Supabase is **superseded and not used**. Its prepared SQL migration was never applied to a live Supabase project.
- Cloudflare D1 stores player data, game state, question IDs, category/age metadata and anti-repeat indexes. Free limit: 500 MB per database, up to 10 databases and 5 GB total per account.
- Cloudflare R2 Standard is selected for question text/answers/explanations as versioned JSON/NDJSON shards, plus images/audio/files; private by default. Free allowance: 10 GB-month.
- Firebase Authentication is selected for sign-in/identity only. Do not enable Identity Platform upgrade without reviewing its separate limits and pricing.
- D1 and R2 have distinct quotas and cannot be treated as one combined database.

## Product data decisions
- Launch question bank target: 76,000 total (60,000 adult/13+, 16,000 children).
- The 500-question discrepancy is reserved within the launch bank; it is not added to the adventure-stage schedule.
- Adventure mode has 200 stages. The currently recorded stage distribution sums to 8,080 operational questions. Final stage rows remain unseeded pending review.
- All eight child categories are available to Babys (3–5), Kids (6–8), and Juniors (9–12), with separate age-specific question banks.
- No question content is inserted by migrations 0001–0003. The approved question payloads will be stored as R2 objects; D1 keeps the searchable metadata and IDs.

## D1 migrations
- `0001_core.sql`: core category, settings, stage and audit tables.
- `0002_seed_catalog_and_settings.sql`: idempotent category and approved settings seed.
- Both migrations were applied successfully to the remote D1 database on 13 November 2026 through GitHub Actions run `43343462323`. Verification returned 36 categories (12 general, 8 babys, 8 kids, 8 juniors) and 15 settings.
- `0003_player_family_progress.sql`: prepared to add Firebase-UID keyed player profiles, family/child records, protected age records, parental settings/consents, progress, stage results, rewards, admin roles and device links. **Not yet applied.**
- The 8,080 stage-question schedule remains unseeded. No question content has been inserted.

## D1 migration workflow
- Workflow: `.github/workflows/d1-migrate.yml`.
- Trigger it manually from GitHub Actions.
- It uses the repository Actions secret `CLOUDFLARE_API_TOKEN` and variable `CLOUDFLARE_ACCOUNT_ID`.
- Never paste token values into chat, source files, screenshots or commit history.

## R2 status
- R2 Standard currently lists 10 GB-month storage, 1 million Class A operations and 10 million Class B operations per month at no charge. D1 Free is 500 MB per database, 10 databases and 5 GB total across the account.
- Bucket and Pages binding are **not yet created**.
- Follow `docs/R2_SETUP.md` after migration 0003 has been verified.

## Firebase status
- Firebase is used for Authentication only in the selected design; Firestore is not selected for question storage.
- Firebase Authentication configuration and server-side ID-token verification are **not yet implemented or verified**.
- Do not use client-supplied UID as identity. Do not expose D1 directly to the browser.

## Security and deployment notes
- All D1 access must go through Pages Functions.
- Scoring, hearts, stars, rewards, age transitions, consent writes, admin roles and protected age records remain server-authoritative.
- Never commit service keys or place them in browser code. Store credentials only in server-side secret settings.
