# Jumjum V5 — Supabase setup

## Current status

- The initial Supabase schema and RLS migration is prepared in Git:
  `supabase/migrations/202611130001_initial_core.sql`.
- It has **not** been applied to a Supabase project.
- No Supabase project connection or credentials have been configured in this repository.
- D1 is already migrated and verified separately; this document covers Supabase only.

## What this migration creates

- Auth-linked player profiles and adult player profiles.
- Family groups and child profile records.
- Isolated, server-only birth-date records.
- Parent settings and consent history.
- Read-only player progress and stage-result views.
- Server-only reward ledger, admin roles and device links.
- Row Level Security (RLS), narrow client grants, and an Auth user-created trigger.

## Security boundaries

- A signed-in user can read their own profile and progress.
- A user can edit only safe profile presentation fields.
- Parents can manage family-group metadata and permitted parental settings.
- Child profile creation, age-band assignment, age verification, consent writes, device linking, role assignment, points, hearts, stars, stage results and rewards are server-authoritative.
- Child profiles cannot be deleted through the client; deactivate them instead so progress and history are not accidentally erased.
- Exact birth dates, admin roles and reward records are not exposed to anon/authenticated clients.
- Never put a Supabase service-role key in browser JavaScript, Git, screenshots, or chat. Store it only in server-side secret settings.

## Apply the migration

1. Open the intended Supabase project in the Supabase Dashboard.
2. Open **SQL Editor** and create a new query.
3. Open the migration file in GitHub:
   `https://github.com/famoelwan/gomgomgames/blob/main/supabase/migrations/202611130001_initial_core.sql`
4. Copy the complete SQL file into the SQL Editor.
5. Confirm that the Dashboard is showing the intended project, then run the query once.
6. If the query reports an error, stop and share the error text only (never share keys or passwords). Do not partially rewrite the migration by hand.
7. After success, inspect **Table Editor** and confirm that the tables listed above exist and RLS is enabled.

## Verification checklist

- [ ] Auth signup creates one row in `public.profiles`.
- [ ] Auth signup creates one row in `public.adult_player_profiles`.
- [ ] A signed-in user cannot read another user's profile or progress.
- [ ] A signed-in user cannot write progress, stage results, points, hearts, stars or rewards.
- [ ] A signed-in user cannot read birth dates or admin roles.
- [ ] A parent cannot access another parent's family or child records.
- [ ] Child profile age-band changes and child profile creation are not exposed to direct client writes.

This is a first foundation migration, not a complete production identity/parental-consent implementation. Before public launch, add server endpoints for signup/profile lifecycle, verified age transitions, parent verification and consent, device pairing, account deletion/data retention, and integration tests. Review the migration against the actual Supabase project before applying it.
