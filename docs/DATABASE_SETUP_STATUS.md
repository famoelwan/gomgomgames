# Jumjum V5 — Database Setup Status

Updated: 13 November 2026

## Confirmed infrastructure
- Git repository: `famoelwan/gomgomgames`, branch `main`.
- Hosting target: Cloudflare Pages.
- D1 database: `jumjumgames`.
- D1 database ID: `8f6841a6-9548-4302-89db-47599721c192`.
- Pages D1 binding: `DB`.
- Wrangler migration directory: `migrations`.

## Data model decisions
- Launch question bank target: 76,000 total (60,000 adult/13+, 16,000 children).
- The 500-question discrepancy is reserved within the launch bank for additional/replacement/approval-ready bank content; it is not added to the adventure-stage schedule.
- Adventure mode has 200 stages. The currently recorded stage distribution sums to 8,080 operational questions. Final stage rows remain unseeded pending review of the detailed stage and heart-reward schedule.
- All eight child categories are available to Babys (3–5), Kids (6–8), and Juniors (9–12), with separate age-specific question banks and age-adapted content. No question is reused across age banks.
- No question content is generated or inserted by the database setup migration.

## D1 migration
- `0001_core.sql`: core tables.
- `0002_seed_catalog_and_settings.sql`: idempotent category and approved settings seed.
- Applied successfully to the existing remote D1 database on 13 November 2026 through GitHub Actions run `43343462323` (commit `91b7c7f316c876d08cfe2b945a35ba966298517e`). Both `0001_core.sql` and `0002_seed_catalog_and_settings.sql` completed successfully. Remote verification returned 36 categories (12 `general`, 8 `babys`, 8 `kids`, 8 `juniors`) and 15 settings. The 8,080 stage-question schedule remains unseeded, and no question content was inserted.

## Applying D1 migrations through GitHub Actions
- Workflow: `.github/workflows/d1-migrate.yml`.
- Trigger it manually from GitHub Actions after adding the repository Actions secret `CLOUDFLARE_API_TOKEN` and repository Actions variable `CLOUDFLARE_ACCOUNT_ID`.
- The token should have only the permissions needed to read the target D1 database and apply D1 migrations for this account. Do not put token values in chat, source files, or commit history.
- The workflow runs `wrangler d1 migrations apply jumjumgames --remote` against the existing database ID configured in `wrangler.toml`, then automatically queries the category total, audience distribution, and settings total.
- Expected results: 36 categories (12 `general`, 8 `babys`, 8 `kids`, 8 `juniors`) and 15 settings. If the migration log shows an unexpected database/account or the counts differ, stop and investigate before retrying.

## Other services
- Supabase is designated for authentication, player profiles, progress, sensitive player records, and protected roles. The initial schema/RLS migration is prepared at `supabase/migrations/202611130001_initial_core.sql`, with instructions at `docs/SUPABASE_SETUP.md`. It has NOT yet been applied to a live Supabase project or verified.
- Firebase is designated for published question content and explanations. Project/database rules and server-only service access are not yet verified.
- Never commit service keys or place them in browser code. Store credentials only in server-side secret settings.
