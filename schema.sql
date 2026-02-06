-- 1. Matches Table (High Frequency Read)
CREATE TABLE IF NOT EXISTS matches (
    id INTEGER PRIMARY KEY,          -- RapidAPI Match ID
    series_id INTEGER,
    title TEXT,
    short_title TEXT,
    status TEXT,                     -- Scheduled, Live, Completed
    start_time INTEGER,              -- Timestamp
    team_a TEXT,
    team_b TEXT,
    team_a_img TEXT,
    team_b_img TEXT,
    last_updated INTEGER
);
CREATE INDEX IF NOT EXISTS idx_matches_status ON matches(status);

-- 2. Players Table (Global Registry)
CREATE TABLE IF NOT EXISTS players (
    id INTEGER PRIMARY KEY,          -- RapidAPI Player ID
    name TEXT,
    role TEXT,                       -- Batsman, Bowler, Allrounder, WK
    image TEXT
);

-- 3. Match Squads (Playing XI)
CREATE TABLE IF NOT EXISTS match_squads (
    match_id INTEGER,
    player_id INTEGER,
    team_name TEXT,                  -- Which team they belong to in this match
    is_playing BOOLEAN DEFAULT 0,    -- Announced in Lineups?
    PRIMARY KEY (match_id, player_id),
    FOREIGN KEY (match_id) REFERENCES matches(id),
    FOREIGN KEY (player_id) REFERENCES players(id)
);

-- 4. Live Scores (Real-time)
CREATE TABLE IF NOT EXISTS live_scores (
    match_id INTEGER PRIMARY KEY,
    status_note TEXT,                -- "MI need 10 runs in 5 balls"
    team_a_score TEXT,               -- "150/4 (18.2)"
    team_b_score TEXT,
    current_over TEXT,               -- Detailed string for display
    batsman_striker TEXT,
    batsman_non_striker TEXT,
    bowler TEXT,
    updated_at INTEGER
);

-- 5. Fantasy Points (Calculated)
CREATE TABLE IF NOT EXISTS fantasy_points (
    match_id INTEGER,
    player_id INTEGER,
    points REAL,
    breakdown TEXT,                  -- JSON string: {"runs": 10, "wickets": 20...}
    PRIMARY KEY (match_id, player_id)
);

-- 6. Leaderboards (Computed)
CREATE TABLE IF NOT EXISTS leaderboards (
    match_id INTEGER,
    contest_id TEXT,                 -- Firestore Contest ID
    user_id TEXT,                    -- Firestore User UID
    total_points REAL,
    rank INTEGER,
    PRIMARY KEY (match_id, contest_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_lb_contest ON leaderboards(contest_id, rank);

-- 7. Vouchers (Reward Credits Redemption)
CREATE TABLE IF NOT EXISTS vouchers (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    code TEXT UNIQUE NOT NULL,
    brand TEXT NOT NULL,
    value INTEGER NOT NULL,
    status TEXT DEFAULT 'active',
    created_at INTEGER NOT NULL,
    redeemed_at INTEGER
);
CREATE INDEX IF NOT EXISTS idx_voucher_user ON vouchers(user_id);
CREATE INDEX IF NOT EXISTS idx_voucher_status ON vouchers(status);
