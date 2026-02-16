-- Migration to allow multiple teams per user in a contest

-- 1. Rename existing table
ALTER TABLE contest_participants RENAME TO contest_participants_old;

-- 2. Create new table with 'id' as PRIMARY KEY
CREATE TABLE contest_participants (
    id TEXT PRIMARY KEY,
    contest_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    team_id TEXT NOT NULL,
    match_id TEXT,
    player_ids TEXT,
    team_name TEXT,
    joined_at INTEGER,
    rank INTEGER DEFAULT 0,
    points REAL DEFAULT 0
);

-- 3. Copy data from old table
-- Note: 'id' in old table might be null if added later, so we use coalesce or generate new UUID if needed.
-- But we just added 'id' column in previous step, so it might be NULL for existing rows.
-- If 'id' is NULL, we must generate one. logical: user_id || '_' || contest_id (but that's unique again).
-- Proper way: We assume 'id' column exists (added in previous step). If it's NULL, we can't use it as PK.
-- Workaround: Generate random ID for nulls or use rowid.
-- SQLite 'hex(randomblob(16))' can work.

INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, player_ids, team_name, joined_at)
SELECT 
    CASE WHEN id IS NULL OR id = '' THEN hex(randomblob(16)) ELSE id END,
    contest_id, user_id, team_id, match_id, player_ids, team_name, joined_at
FROM contest_participants_old;

-- 4. Re-create Indices (Non-Unique for contest+user)
CREATE INDEX idx_cp_contest_user ON contest_participants(contest_id, user_id);
CREATE INDEX idx_cp_user ON contest_participants(user_id);
CREATE INDEX idx_cp_match ON contest_participants(match_id);

-- 5. Drop old table
DROP TABLE contest_participants_old;
