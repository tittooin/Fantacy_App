-- Schema V8: Economy Engine State
-- Tracks the automation state for each match to prevent redundant checks.

CREATE TABLE IF NOT EXISTS auto_contests (
    match_id TEXT PRIMARY KEY,
    last_tier_unlocked INTEGER DEFAULT 0, -- 0=Initial, 5, 10, 29, 49
    created_at INTEGER
);

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_auto_contests_match_id ON auto_contests(match_id);
