-- D1 Schema V4: Automation, Stats, and Zero-Write Optimization

-- 1. Users Table (Lite) - For Admin Stats & Leaderboard lookup (Zero Firestore Read)
-- Synced from Worker during Auth/Join
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    email TEXT,
    display_name TEXT,
    photo_url TEXT,
    joined_at INTEGER,
    last_active INTEGER,
    is_restricted INTEGER DEFAULT 0
);

-- 2. Contests Table - For Admin Stats & Listing (Zero Firestore Read)
CREATE TABLE IF NOT EXISTS contests (
    id TEXT PRIMARY KEY,
    match_id TEXT,
    entry_fee INTEGER,
    total_spots INTEGER,
    filled_spots INTEGER,
    status TEXT, -- Live, Upcoming, Completed, Cancelled
    created_at INTEGER
);

-- 3. Match Squads - For TeamBuilder (Zero Firestore Read)
CREATE TABLE IF NOT EXISTS match_squads (
    match_id TEXT PRIMARY KEY,
    series_id INTEGER,
    team_a_roster JSON, -- Array of players
    team_b_roster JSON, -- Array of players
    playing_11_a JSON, -- Array of IDs
    playing_11_b JSON, -- Array of IDs
    last_updated INTEGER
);

-- 4. Payouts Audit - For tracking distributed prizes
CREATE TABLE IF NOT EXISTS contest_payouts (
    contest_id TEXT PRIMARY KEY,
    match_id TEXT,
    total_distributed REAL,
    processed_at INTEGER
);
