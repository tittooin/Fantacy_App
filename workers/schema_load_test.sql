-- Schema for Load Test Sandbox (Isolated Tables)
-- Prefix: test_*

-- 1. Test Matches
CREATE TABLE IF NOT EXISTS test_matches (
    id TEXT PRIMARY KEY,
    title TEXT,
    status TEXT,
    start_time INTEGER,
    end_time INTEGER,
    team_a TEXT, -- JSON
    team_b TEXT, -- JSON
    venue TEXT, -- JSON
    series_id INTEGER,
    format TEXT
);

-- 2. Test Contests
CREATE TABLE IF NOT EXISTS test_contests (
    id TEXT PRIMARY KEY,
    match_id TEXT,
    entry_fee INTEGER,
    total_spots INTEGER,
    filled_spots INTEGER DEFAULT 0,
    category TEXT,
    prize_pool INTEGER, -- calculated
    winning_breakdown TEXT, -- JSON
    is_guaranteed BOOLEAN DEFAULT 0,
    is_flexible BOOLEAN DEFAULT 0,
    status TEXT DEFAULT 'Upcoming',
    created_at INTEGER
);

-- 3. Test Participants
CREATE TABLE IF NOT EXISTS test_participants (
    id TEXT PRIMARY KEY,
    contest_id TEXT,
    user_id TEXT,
    team_id TEXT,
    match_id TEXT,
    player_ids TEXT, -- JSON
    team_name TEXT,
    joined_at INTEGER
);

-- 4. Insert Dummy Match (LOAD_TEST_MATCH)
INSERT OR IGNORE INTO test_matches (id, title, status, start_time) 
VALUES ('LOAD_TEST_MATCH', 'Load Test Match', 'Upcoming', 1799999999999);

-- 5. Insert Dummy Contest
-- ID will be fixed for test: 'LOAD_TEST_CONTEST_001'
INSERT OR IGNORE INTO test_contests (id, match_id, entry_fee, total_spots, filled_spots, category, status, created_at)
VALUES ('LOAD_TEST_CONTEST_001', 'LOAD_TEST_MATCH', 1, 10000, 0, 'Load Test', 'Upcoming', 1700000000000);
