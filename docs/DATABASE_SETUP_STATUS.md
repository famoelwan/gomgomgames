# Jumjum V5 — Database Setup Status

Updated: 11 November 2026

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
- Applying a migration to Git does not itself apply it to the live D1 database. The D1 migration must be applied to the existing production database through Wrangler or the Cloudflare D1 console, then verified with counts.

## Applying D1 migrations through GitHub Actions
- Workflow: `.github/workflows/d1-migrate.yml`.
- Trigger it manually from GitHub Actions after adding the repository Actions secret `CLOUDFLARE_API_TOKEN` and repository Actions variable `CLOUDFLARE_ACCOUNT_ID`.
- The token should have only the permissions needed to read the target D1 database and apply D1 migrations for this account. Do not put token values in chat, source files, or commit history.
- The workflow runs `wrangler d1 migrations apply jumjumgames --remote` against the existing database ID configured in `wrangler.toml`.
- Verify the workflow log reports both migrations as applied/already applied, then query D1 for 36 categories and 15 settings. If the migration log shows an unexpected database/account, stop and do not retry.

## Other services
- Supabase is designated for authentication, player profiles, progress, sensitive player records, and protected roles. Its project/schema/RLS setup is not yet verified from this repository.
- Firebase is designated for published question content and explanations. Project/database rules and server-only service access are not yet verified.
- Never commit service keys or place them in browser code. Store credentials only in server-side secret settings.
