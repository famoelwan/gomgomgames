# Jumjum V5 — Storage and backend architecture

## Decision (13 November 2026)

Supabase is **not part of the selected architecture**. Its initial migration was prepared but never applied to a live project. Do not run or rely on that migration.

### Selected services

| Responsibility | Service | Free allowance currently published |
|---|---|---:|
| Web hosting and API | Cloudflare Pages + Pages Functions | Existing project |
| Structured player/game metadata | Cloudflare D1 | 5 GB total per account; 500 MB maximum per database on Free; up to 10 databases; 5 million rows read/day and 100,000 rows written/day |
| Images, audio and other binary assets | Cloudflare R2 Standard | 10 GB-month; 1 million Class A and 10 million Class B operations/month |
| Sign-in and identity | Firebase Authentication (base Firebase Auth, not Identity Platform upgrade) | Most sign-in methods no-cost; phone SMS is billed |
| Published question text, answers and explanations | Private Cloudflare R2 JSON/NDJSON shards, delivered only through server APIs | Shares the 10 GB-month R2 object allowance |
| Question media and large files | Private R2 bucket | Separate object-storage allowance |

Official pricing references:
- Cloudflare D1: https://developers.cloudflare.com/d1/platform/pricing/
- Cloudflare R2: https://developers.cloudflare.com/r2/pricing/
- Firebase: https://firebase.google.com/pricing/

D1 and R2 are different storage types. Do not describe them as one interchangeable 15 GB database: D1 stores relational rows; R2 stores objects/files. Current free limits are up to 5 GB total across the D1 account (but only 500 MB in each free D1 database, up to 10 databases) plus 10 GB-month of R2 Standard storage. This is up to 15 GB across two different services, not 15 GB in one database. Store the large question payloads as versioned R2 shards; keep player progress, question IDs, category/age metadata, reservation/anti-repeat state and indexes in D1.

## Why not Turso or Firestore for this migration?

Turso Free currently lists 5 GB of storage across its plan and up to 100 databases; D1 Free has 5 GB total across the account but a 500 MB cap per database. Turso could be reconsidered if a single relational database needs more than 500 MB, but it would add another provider and require a separate security/integration design. For now, the question bank is placed in R2 objects, so the current D1 database remains for relational metadata and player state. Firestore's free database quota is 1 GiB.

## Supabase migration disposition

- The Supabase SQL migration was committed but not applied to a live project.
- It is superseded by `migrations/0003_player_family_progress.sql`.
- Do not apply the old Supabase migration.
- No Supabase account, project, keys or credentials are required for the selected design.

## Security model

D1 is not exposed directly to the browser. All reads and writes go through Cloudflare Pages Functions:
1. Verify the Firebase ID token server-side (signature, issuer, audience, expiry and subject).
2. Derive the Firebase UID from the verified token; never trust a UID supplied by the client.
3. Apply owner checks in every query and mutation.
4. Keep scoring, stars, hearts, rewards, age transitions, parental consent writes, admin roles and protected age records server-authoritative.
5. Do not return exact birth dates, role tables, reward ledger rows or audit internals to ordinary clients.
6. Use prepared SQL statements and strict request validation.
7. Add rate limits and audit events to sensitive endpoints.

Firebase Authentication is used for account identity only. Do not enable the Identity Platform upgrade until its different quotas have been reviewed. Avoid phone/SMS sign-in in the initial release unless its costs are explicitly approved. The question bank is not stored in Firestore.

## R2 security

- Create a private Standard bucket; do not enable public bucket access by default.
- Bind the bucket to Pages Functions as `ASSETS`.
- Browser uploads/downloads must pass through authorized endpoints or short-lived signed URLs.
- Validate MIME type, file size, ownership and allowed asset paths on the server.
- Never store credentials in source code or browser JavaScript.
- Keep a metadata row in D1 for each managed asset; the binary itself belongs in R2.

## Capacity and scale

The Free plan is suitable for prototyping, not a promise of unlimited production capacity. D1's Free daily query/write quotas may be reached before its 5 GB storage fills. Monitor rows read/written, storage, R2 operations, bandwidth and error rates.

Published D1 paid storage is $0.75 per GB-month above the included 5 GB account allowance; paid per-database maximum is 10 GB. R2 Standard storage is $0.015 per GB-month above its included 10 GB-month, with no egress fee. Re-check official pricing before enabling billing because rates and quotas can change.

## Migration and deployment status

- Existing D1 core/catalog migrations 0001 and 0002 are already applied.
- Migration 0003 is prepared and passed a local SQLite syntax/structure check, but **not yet applied to the remote D1 database**.
- R2 bucket and binding are **not yet created**.
- Firebase Authentication configuration and server token verification are **not yet implemented or verified**.
- No question content or 8,080-stage schedule is inserted by this migration.

Next: apply D1 migration 0003 through the existing GitHub Actions workflow, then verify table counts and constraints. Create the private R2 bucket and configure its binding, then upload question-bank shards and implement/test Firebase token verification before exposing player APIs.
