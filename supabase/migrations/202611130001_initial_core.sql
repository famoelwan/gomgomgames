-- Jumjum V5 Supabase foundation
-- Apply only to the intended Supabase project after reviewing this migration.
-- Client sessions may read their own permitted profile/progress data.
-- All scoring, rewards, age transitions, role assignment and sensitive writes are server-authoritative.

begin;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Player' check (char_length(display_name) between 1 and 40),
  avatar_url text,
  locale text not null default 'ar' check (locale in ('ar','en')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.adult_player_profiles (
  user_id uuid primary key references public.profiles(user_id) on delete cascade,
  competition_enabled boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.family_groups (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  family_name text not null default 'My Family' check (char_length(family_name) between 1 and 60),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (owner_user_id)
);

create table if not exists public.child_profiles (
  id uuid primary key default gen_random_uuid(),
  family_group_id uuid not null references public.family_groups(id) on delete cascade,
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 40),
  age_band text not null check (age_band in ('babys','kids','juniors')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, owner_user_id)
);

create index if not exists child_profiles_owner_idx on public.child_profiles(owner_user_id);
create index if not exists child_profiles_family_idx on public.child_profiles(family_group_id);

-- Exact dates of birth are deliberately isolated from ordinary profile tables.
-- No anon/authenticated grants or RLS policies are provided for this table.
create table if not exists public.protected_age_records (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  player_user_id uuid references auth.users(id) on delete cascade,
  child_profile_id uuid references public.child_profiles(id) on delete cascade,
  birth_date date not null,
  verification_method text,
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  check ((player_user_id is not null)::integer + (child_profile_id is not null)::integer = 1)
);

create unique index if not exists protected_age_records_adult_unique
  on public.protected_age_records(player_user_id) where player_user_id is not null;
create unique index if not exists protected_age_records_child_unique
  on public.protected_age_records(child_profile_id) where child_profile_id is not null;

create table if not exists public.parental_settings (
  child_profile_id uuid primary key references public.child_profiles(id) on delete cascade,
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  allow_real_world_tasks boolean not null default false,
  allow_competitions boolean not null default false,
  updated_at timestamptz not null default now()
);

create table if not exists public.parent_consents (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  child_profile_id uuid not null references public.child_profiles(id) on delete cascade,
  consent_type text not null,
  consent_version text not null,
  status text not null check (status in ('granted','withdrawn','pending')),
  recorded_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb
);

create index if not exists parent_consents_owner_idx
  on public.parent_consents(owner_user_id, recorded_at desc);

-- Read-only progress projections for clients. Trusted server code writes these rows.
create table if not exists public.player_progress (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  player_user_id uuid references auth.users(id) on delete cascade,
  child_profile_id uuid references public.child_profiles(id) on delete cascade,
  adventure_stage integer not null default 1 check (adventure_stage between 1 and 200),
  competition_points numeric(14,2) not null default 0 check (competition_points >= 0),
  achievement_points integer not null default 0 check (achievement_points >= 0),
  hearts numeric(8,2) not null default 0 check (hearts >= 0),
  updated_at timestamptz not null default now(),
  check ((player_user_id is not null)::integer + (child_profile_id is not null)::integer = 1)
);

create unique index if not exists player_progress_adult_unique
  on public.player_progress(player_user_id) where player_user_id is not null;
create unique index if not exists player_progress_child_unique
  on public.player_progress(child_profile_id) where child_profile_id is not null;
create index if not exists player_progress_owner_idx on public.player_progress(owner_user_id);

create table if not exists public.stage_results (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  player_user_id uuid references auth.users(id) on delete cascade,
  child_profile_id uuid references public.child_profiles(id) on delete cascade,
  stage_number integer not null check (stage_number between 1 and 200),
  attempt_number integer not null check (attempt_number > 0),
  correct_answers integer not null default 0 check (correct_answers >= 0),
  total_questions integer not null check (total_questions > 0),
  stars integer not null check (stars between 1 and 3),
  achievement_points_awarded integer not null default 0 check (achievement_points_awarded >= 0),
  completed_at timestamptz not null default now(),
  check ((player_user_id is not null)::integer + (child_profile_id is not null)::integer = 1)
);

create index if not exists stage_results_owner_completed_idx
  on public.stage_results(owner_user_id, completed_at desc);

-- Idempotency ledger: service-side only; clients cannot award or edit rewards.
create table if not exists public.reward_ledger (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  player_user_id uuid references auth.users(id) on delete cascade,
  child_profile_id uuid references public.child_profiles(id) on delete cascade,
  event_key text not null,
  reward_type text not null,
  amount numeric(14,2) not null,
  created_at timestamptz not null default now(),
  check ((player_user_id is not null)::integer + (child_profile_id is not null)::integer = 1),
  unique (event_key)
);

create table if not exists public.admin_roles (
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in (
    'owner','super_admin','content_editor','content_reviewer',
    'stage_manager','player_support','analyst'
  )),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  primary key (user_id, role)
);

create table if not exists public.parent_device_links (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  child_profile_id uuid not null references public.child_profiles(id) on delete cascade,
  device_label text,
  linked_at timestamptz not null default now(),
  revoked_at timestamptz
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists family_groups_set_updated_at on public.family_groups;
create trigger family_groups_set_updated_at before update on public.family_groups
for each row execute function public.set_updated_at();

drop trigger if exists child_profiles_set_updated_at on public.child_profiles;
create trigger child_profiles_set_updated_at before update on public.child_profiles
for each row execute function public.set_updated_at();

drop trigger if exists parental_settings_set_updated_at on public.parental_settings;
create trigger parental_settings_set_updated_at before update on public.parental_settings
for each row execute function public.set_updated_at();

-- Create a basic profile after Supabase Auth creates a user.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (user_id, display_name)
  values (
    new.id,
    coalesce(nullif(left(new.raw_user_meta_data ->> 'display_name', 40), ''), 'Player')
  )
  on conflict (user_id) do nothing;

  insert into public.adult_player_profiles (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();

alter table public.profiles enable row level security;
alter table public.adult_player_profiles enable row level security;
alter table public.family_groups enable row level security;
alter table public.child_profiles enable row level security;
alter table public.protected_age_records enable row level security;
alter table public.parental_settings enable row level security;
alter table public.parent_consents enable row level security;
alter table public.player_progress enable row level security;
alter table public.stage_results enable row level security;
alter table public.reward_ledger enable row level security;
alter table public.admin_roles enable row level security;
alter table public.parent_device_links enable row level security;

-- Profiles: users may read their own profile and edit only safe presentation fields.
drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles
for select to authenticated using (user_id = (select auth.uid()));

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

grant select on public.profiles to authenticated;
grant update (display_name, avatar_url, locale) on public.profiles to authenticated;

-- Adult player profile: private to its owner; changes with competitive impact stay server-side.
drop policy if exists adult_player_profiles_select_own on public.adult_player_profiles;
create policy adult_player_profiles_select_own on public.adult_player_profiles
for select to authenticated using (user_id = (select auth.uid()));
grant select on public.adult_player_profiles to authenticated;

-- Family owner controls family metadata and child profile setup.
drop policy if exists family_groups_owner_all on public.family_groups;
create policy family_groups_owner_all on public.family_groups
for all to authenticated
using (owner_user_id = (select auth.uid()))
with check (owner_user_id = (select auth.uid()));
grant select, insert, update, delete on public.family_groups to authenticated;

drop policy if exists child_profiles_owner_all on public.child_profiles;
create policy child_profiles_owner_all on public.child_profiles
for all to authenticated
using (
  owner_user_id = (select auth.uid())
  and exists (
    select 1 from public.family_groups fg
    where fg.id = child_profiles.family_group_id
      and fg.owner_user_id = (select auth.uid())
  )
)
with check (
  owner_user_id = (select auth.uid())
  and exists (
    select 1 from public.family_groups fg
    where fg.id = child_profiles.family_group_id
      and fg.owner_user_id = (select auth.uid())
  )
);
grant select, insert, update, delete on public.child_profiles to authenticated;

-- Parent-managed settings are limited to children owned by the current parent.
drop policy if exists parental_settings_owner_all on public.parental_settings;
create policy parental_settings_owner_all on public.parental_settings
for all to authenticated
using (
  owner_user_id = (select auth.uid())
  and exists (
    select 1 from public.child_profiles cp
    where cp.id = parental_settings.child_profile_id
      and cp.owner_user_id = (select auth.uid())
  )
)
with check (
  owner_user_id = (select auth.uid())
  and exists (
    select 1 from public.child_profiles cp
    where cp.id = parental_settings.child_profile_id
      and cp.owner_user_id = (select auth.uid())
  )
);
grant select, insert, update, delete on public.parental_settings to authenticated;

-- Parent may view consent history; consent creation/withdrawal must go through trusted server logic.
drop policy if exists parent_consents_select_owner on public.parent_consents;
create policy parent_consents_select_owner on public.parent_consents
for select to authenticated using (owner_user_id = (select auth.uid()));
grant select on public.parent_consents to authenticated;

-- Progress/results are readable by the owning account only. No client write grants or policies.
drop policy if exists player_progress_select_owner on public.player_progress;
create policy player_progress_select_owner on public.player_progress
for select to authenticated using (owner_user_id = (select auth.uid()));
grant select on public.player_progress to authenticated;

drop policy if exists stage_results_select_owner on public.stage_results;
create policy stage_results_select_owner on public.stage_results
for select to authenticated using (owner_user_id = (select auth.uid()));
grant select on public.stage_results to authenticated;

-- Explicitly server-only tables: RLS enabled, no authenticated/anon policies or grants.
revoke all on public.protected_age_records from anon, authenticated;
revoke all on public.reward_ledger from anon, authenticated;
revoke all on public.admin_roles from anon, authenticated;
revoke all on public.parent_device_links from anon, authenticated;

-- Child consent rows are visible only to their owning parent; writes remain server-only.
revoke insert, update, delete on public.parent_consents from anon, authenticated;

commit;
