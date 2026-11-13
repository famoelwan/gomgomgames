# Jumjum V5 — Storage and backend architecture

## Approved direction (13 November 2026)

- Keep the existing Cloudflare Pages + Pages Functions hosting.
- Keep Cloudflare D1 for the existing game catalog, categories, settings, stage configuration and operational data.
- Use **Turso Free as the replacement for Supabase** for player profiles, adult profiles, family groups, child profiles, protected age records, parental settings/consents, player progress, stage results, reward ledger, admin roles and device links.
- Use Firebase Authentication for sign-in/identity only. Cloudflare Pages Functions verify Firebase ID tokens before accessing Turso or D1.
- Images are hosted externally for now through the user's existing Servimg and FAMO-PIC arrangements. Store only approved image URLs and metadata in the databases. Do not use Cloudflare R2; the user cannot provide the required payment card.

## Free-tier capacity (published pricing; verify before launch)

| Service | Free allowance | Role |
|---|---:|---|
| Cloudflare D1 | 5 GB total/account; up to 10 databases, each max 500 MB on Free | Existing game data/config |
| Turso | 5 GB storage, up to 100 databases, 500 million rows read/month, 10 million rows written/month | Player and family data |
| Servimg / FAMO-PIC | Depends on each provider/account and its current terms | Temporary image hosting |

Turso explicitly advertises a Free plan with no credit card required. The published paid Developer plan is currently $5.99/month on monthly billing (or $4.99/month equivalent on yearly billing), with 9 GB included; usage and prices may change.

Official references:
- Turso pricing: https://turso.tech/pricing
- Cloudflare D1 limits: https://developers.cloudflare.com/d1/platform/limits/
- Cloudflare Workers + Turso integration: https://developers.cloudflare.com/workers/databases/third-party-integrations/turso/

Do not add the 5 GB D1 and 5 GB Turso quotas together as if they were one database. They are separate services with separate limits. D1 Free has a 500 MB per-database ceiling even though the account total is 5 GB.

## Supabase disposition

- Supabase is no longer the target backend; Turso replaces it.
- The user reported that the Supabase SQL Editor returned `Success. No rows returned`. The Supabase migration may therefore have created tables in the live project, but table/RLS verification was not completed.
- Removing Supabase files from GitHub does not delete the live Supabase project or its tables. Do not delete the Supabase project/data until checking for records/dependencies and exporting anything needed.
- The previous Supabase migration and setup guide remain recoverable from Git history; their removal from the current tree was premature.

## Security architecture

1. Browser calls Cloudflare Pages Functions only; it never connects directly to D1 or Turso.
2. Verify Firebase ID token server-side (signature, issuer, audience, expiry, subject).
3. Derive Firebase UID only from the verified token; never trust a client-supplied UID.
4. Check owner authorization in every query/mutation. Turso does not provide Supabase-style RLS, so authorization must be enforced in server code and tested.
5. Scoring, stars, hearts, rewards, age transitions, parental consent writes, admin roles and protected age records are server-authoritative.
6. Never return exact birth dates, admin role internals or reward ledger internals to ordinary clients.
7. Use prepared statements, strict validation, rate limits and audit events.

## Images

- Keep Servimg and FAMO-PIC as temporary image hosts while they meet project needs and provider terms.
- Store the image URL, provider, owner, category, dimensions and review state as metadata.
- Do not put private child information or identity details in image URLs or filenames.
- Keep a migration path so images can later move to another host without changing question records; use stable internal asset IDs and a URL mapping table.
- Verify hotlinking, bandwidth, retention and terms for each host before public launch.

## Migrations and status

- D1 migrations 0001 and 0002 are applied and verified.
- Player/family migration is now `turso/migrations/0001_player_family_progress.sql`; it is prepared but not yet applied to a live Turso database.
- Turso database, token secret, Cloudflare binding/integration and server-side adapter are not yet configured.
- Firebase Authentication token verification is not yet implemented/verified.
- No question content or 8,080-stage schedule is seeded by the player migration.
- R2 is not used in this architecture.
