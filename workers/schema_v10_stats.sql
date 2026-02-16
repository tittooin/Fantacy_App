-- Schema for Player Stats Cache
CREATE TABLE IF NOT EXISTS player_stats (
    player_id TEXT PRIMARY KEY,
    fantasy_rating REAL DEFAULT 50.0,
    credits REAL DEFAULT 8.0,
    role_normalized TEXT, -- 'WK', 'BAT', 'AR', 'BOWL'
    last_updated INTEGER
);

-- Index for fast lookup
CREATE INDEX IF NOT EXISTS idx_player_stats_role ON player_stats(role_normalized);
