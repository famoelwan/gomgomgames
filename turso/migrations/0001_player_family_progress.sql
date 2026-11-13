-- Jumjum V5 player/family/progress schema for Turso (libSQL / SQLite).
-- Apply to the Turso database, NOT Cloudflare D1.
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS player_profiles (
  firebase_uid TEXT PRIMARY KEY,
  display_name TEXT NOT NULL DEFAULT 'Player' CHECK (length(display_name) BETWEEN 1 AND 40),
  avatar_key TEXT,
  locale TEXT NOT NULL DEFAULT 'ar' CHECK (locale IN ('ar','en')),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS adult_player_profiles (
  firebase_uid TEXT PRIMARY KEY REFERENCES player_profiles(firebase_uid) ON DELETE CASCADE,
  competition_enabled INTEGER NOT NULL DEFAULT 1 CHECK (competition_enabled IN (0,1)),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS family_groups (
  id TEXT PRIMARY KEY,
  owner_firebase_uid TEXT NOT NULL UNIQUE REFERENCES player_profiles(firebase_uid) ON DELETE CASCADE,
  family_name TEXT NOT NULL DEFAULT 'My Family' CHECK (length(family_name) BETWEEN 1 AND 60),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (id, owner_firebase_uid)
);

CREATE TABLE IF NOT EXISTS child_profiles (
  id TEXT PRIMARY KEY,
  family_group_id TEXT NOT NULL,
  owner_firebase_uid TEXT NOT NULL REFERENCES player_profiles(firebase_uid) ON DELETE CASCADE,
  display_name TEXT NOT NULL CHECK (length(display_name) BETWEEN 1 AND 40),
  age_band TEXT NOT NULL CHECK (age_band IN ('babys','kids','juniors')),
  is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0,1)),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (id, owner_firebase_uid),
  FOREIGN KEY (family_group_id, owner_firebase_uid)
    REFERENCES family_groups(id, owner_firebase_uid) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_child_profiles_owner ON child_profiles(owner_firebase_uid);
CREATE INDEX IF NOT EXISTS idx_child_profiles_family ON child_profiles(family_group_id);

-- Exact dates of birth are isolated. No API may return this table to a client.
CREATE TABLE IF NOT EXISTS protected_age_records (
  id TEXT PRIMARY KEY,
  owner_firebase_uid TEXT NOT NULL REFERENCES player_profiles(firebase_uid) ON DELETE CASCADE,
  player_firebase_uid TEXT REFERENCES player_profiles(firebase_uid) ON DELETE CASCADE,
  child_profile_id TEXT REFERENCES child_profiles(id) ON DELETE RESTRICT,
  birth_date TEXT NOT NULL,
  verification_method TEXT,
  verified_at TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK ((player_firebase_uid IS NOT NULL) <> (child_profile_id IS NOT NULL))
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_protected_age_adult_unique
  ON protected_age_records(player_firebase_uid) WHERE player_firebase_uid IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_protected_age_child_unique
  ON protected_age_records(child_profile_id) WHERE child_profile_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS parental_settings (
  child_profile_id TEXT PRIMARY KEY REFERENCES child_profiles(id) ON DELETE CASCADE,
  owner_firebase_uid TEXT NOT NULL REFERENCES player_profiles(firebase_uid) ON DELETE CASCADE,
  allow_real_world_tasks INTEGER NOT NULL DEFAULT 0 CHECK (allow_real_world_tasks IN (0,1)),
  allow_competitions INTEGER NOT NULL DEFAULT 0 CHECK (allow_competitions IN (0,1)),
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS parent_consents (
  id TEXT PRIMARY KEY,
  owner_firebase_uid TEXT NOT NULL REFERENCES player_profiles(firebase_uid) ON DELETE CASCADE,
  child_profile_id TEXT NOT NULL REFERENCES child_profiles(id) ON DELETE CASCADE,
  consent_type TEXT NOT NULL,
  consent_version TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('granted','withdrawn','pending')),
  recorded_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  metadata_json TEXT NOT NULL DEFAULT '{}'
);
CREATE INDEX IF NOT EXISTS idx_parent_consents_owner
  ON parent_consents(owner_firebase_uid, recorded_at DESC);

CREATE TABLE IF NOT EXISTS player_progress (
  id TEXT PRIMARY KEY,
  owner_firebase_uid TEXT NOT NULL REFERENCES player_profiles(firebase_uid) ON DELETE CASCADE,
  player_firebase_uid TEXT REFERENCES player_profiles(firebase_uid) ON DELETE CASCADE,
  child_profile_id TEXT REFERENCES child_profiles(id) ON DELETE CASCADE,
  adventure_stage INTEGER NOT NULL DEFAULT 1 CHECK (adventure_stage BETWEEN 1 AND 200),
  competition_points REAL NOT NULL DEFAULT 0 CHECK (competition_points >= 0),
  achievement_points INTEGER NOT NULL DEFAULT 0 CHECK (achievement_points >= 0),
  hearts REAL NOT NULL DEFAULT 0 CHECK (hearts >= 0),
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK ((player_firebase_uid IS NOT NULL) <> (child_profile_id IS NOT NULL))
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_player_progress_adult_unique
  ON player_progress(player_firebase_uid) WHERE player_firebase_uid IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_player_progress_child_unique
  ON player_progress(child_profile_id) WHERE child_profile_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_player_progress_owner ON player_progress(owner_firebase_uid);

CREATE TABLE IF NOT EXISTS stage_results (
  id TEXT PRIMARY KEY,
  owner_firebase_uid TEXT NOT NULL REFERENCES player_profiles(firebase_uid) ON DELETE CASCADE,
  player_firebase_uid TEXT REFERENCES player_profiles(firebase_uid) ON DELETE CASCADE,
  child_profile_id TEXT REFERENCES child_profiles(id) ON DELETE CASCADE,
  stage_number INTEGER NOT NULL CHECK (stage_number BETWEEN 1 AND 200),
  attempt_number INTEGER NOT NULL CHECK (attempt_number > 0),
  correct_answers INTEGER NOT NULL DEFAULT 0 CHECK (correct_answers >= 0),
  total_questions INTEGER NOT NULL CHECK (total_questions > 0),
  stars INTEGER NOT NULL CHECK (stars BETWEEN 1 AND 3),
  achievement_points_awarded INTEGER NOT NULL DEFAULT 0 CHECK (achievement_points_awarded >= 0),
  completed_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK ((player_firebase_uid IS NOT NULL) <> (child_profile_id IS NOT NULL))
);
CREATE INDEX IF NOT EXISTS idx_stage_results_owner_completed
  ON stage_results(owner_firebase_uid, completed_at DESC);

-- Server-only idempotency ledger; never accept reward amounts from the browser.
CREATE TABLE IF NOT EXISTS reward_ledger (
  id TEXT PRIMARY KEY,
  owner_firebase_uid TEXT NOT NULL REFERENCES player_profiles(firebase_uid) ON DELETE CASCADE,
  player_firebase_uid TEXT REFERENCES player_profiles(firebase_uid) ON DELETE CASCADE,
  child_profile_id TEXT REFERENCES child_profiles(id) ON DELETE CASCADE,
  event_key TEXT NOT NULL UNIQUE,
  reward_type TEXT NOT NULL,
  amount REAL NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK ((player_firebase_uid IS NOT NULL) <> (child_profile_id IS NOT NULL))
);

CREATE TABLE IF NOT EXISTS admin_roles (
  firebase_uid TEXT NOT NULL REFERENCES player_profiles(firebase_uid) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN (
    'owner','super_admin','content_editor','content_reviewer',
    'stage_manager','player_support','analyst'
  )),
  is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0,1)),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (firebase_uid, role)
);

CREATE TABLE IF NOT EXISTS parent_device_links (
  id TEXT PRIMARY KEY,
  owner_firebase_uid TEXT NOT NULL REFERENCES player_profiles(firebase_uid) ON DELETE CASCADE,
  child_profile_id TEXT NOT NULL REFERENCES child_profiles(id) ON DELETE CASCADE,
  device_label TEXT,
  linked_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  revoked_at TEXT
);
CREATE INDEX IF NOT EXISTS idx_parent_device_links_owner
  ON parent_device_links(owner_firebase_uid, child_profile_id);

-- Client APIs must be allow-listed. Sensitive tables (protected_age_records,
-- parent_consents writes, reward_ledger, admin_roles, parent_device_links)
-- are accessed only by server-side functions after identity and role checks.
