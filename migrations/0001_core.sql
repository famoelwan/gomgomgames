PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS categories (
  id TEXT PRIMARY KEY,
  slug TEXT NOT NULL UNIQUE,
  name_ar TEXT NOT NULL,
  audience TEXT NOT NULL CHECK (audience IN ('general', 'babys', 'kids', 'juniors')),
  is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS game_settings (
  setting_key TEXT PRIMARY KEY,
  setting_value TEXT NOT NULL,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stage_config (
  stage_number INTEGER PRIMARY KEY CHECK (stage_number BETWEEN 1 AND 200),
  questions_count INTEGER NOT NULL CHECK (questions_count > 0),
  difficulty TEXT NOT NULL CHECK (difficulty IN (
    'very_easy', 'easy_relative', 'easy', 'medium_easy',
    'medium_rel', 'medium', 'hard', 'very_hard', 'extreme_hard'
  )),
  time_limit_seconds INTEGER NOT NULL DEFAULT 30 CHECK (time_limit_seconds > 0),
  hearts_reward_units INTEGER NOT NULL DEFAULT 0 CHECK (hearts_reward_units >= 0),
  is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))
);

CREATE TABLE IF NOT EXISTS admin_audit_log (
  id TEXT PRIMARY KEY,
  actor_user_id TEXT NOT NULL,
  action TEXT NOT NULL,
  target_type TEXT NOT NULL,
  target_id TEXT,
  database_name TEXT NOT NULL,
  before_json TEXT,
  after_json TEXT,
  result TEXT NOT NULL CHECK (result IN ('success', 'failure')),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_categories_audience_active
  ON categories(audience, is_active, sort_order);

CREATE INDEX IF NOT EXISTS idx_admin_audit_created
  ON admin_audit_log(created_at);
