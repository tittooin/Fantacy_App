-- D1 Schema Migration for Leaderboards (Zero Firestore Reads)
-- run: wrangler d1 execute fantasy-db --file=workers/schema_v2_leaderboard.sql

-- 1. Contest Participants Table (Synced from Join)
CREATE TABLE IF NOT EXISTS contest_participants (
    contest_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    team_id TEXT,
    player_ids TEXT, -- JSON Array of player IDs in the team
    team_name TEXT,
    joined_at INTEGER,
    PRIMARY KEY (contest_id, user_id)
);

-- 2. Leaderboards Table (Client Read Only)
CREATE TABLE IF NOT EXISTS contest_leaderboards (
    contest_id TEXT PRIMARY KEY,
    match_id TEXT,
    data TEXT, -- JSON Array: [{rank, userId, displayName, teamName, points, team_id}]
    last_updated INTEGER
);

-- Index for efficient lookup during leaderboard calculation
CREATE INDEX IF NOT EXISTS idx_participants_contest ON contest_participants(contest_id);
