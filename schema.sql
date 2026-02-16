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
    score_details TEXT,              -- JSON Full Scorecard
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

-- 7. Vouchers (Legacy - Keep for record)
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

-- 8. Voucher Requests (New Manual Redemption)
CREATE TABLE IF NOT EXISTS voucher_requests (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    brand TEXT NOT NULL,
    credits INTEGER NOT NULL,
    status TEXT DEFAULT 'pending', -- pending, approved, rejected
    voucher_code TEXT,             -- Filled by Admin
    created_at INTEGER NOT NULL,
    approved_at INTEGER
);
CREATE INDEX IF NOT EXISTS idx_vr_user ON voucher_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_vr_status ON voucher_requests(status);

-- 9. Users Table (D1 Wallet Master)
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    name TEXT,
    email TEXT,
    photo_url TEXT,
    deposit_credits REAL DEFAULT 0,  -- For Joining Contests
    winning_credits REAL DEFAULT 0,  -- For Redemption
    joined_at INTEGER,
    last_active INTEGER,
    is_restricted BOOLEAN DEFAULT 0
);

-- 10. Transactions (Audit Trail)
CREATE TABLE IF NOT EXISTS transactions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    type TEXT NOT NULL,              -- 'deposit', 'contest_join', 'winnings', 'refund', 'withdrawal_request'
    amount REAL NOT NULL,
    match_id INTEGER,
    contest_id TEXT,
    created_at INTEGER NOT NULL,
    status TEXT DEFAULT 'success'
);
CREATE INDEX IF NOT EXISTS idx_txn_user ON transactions(user_id);
-- 11. Contests Table (Core logic)
CREATE TABLE IF NOT EXISTS contests (
    id TEXT PRIMARY KEY,
    match_id INTEGER NOT NULL,
    entry_fee REAL DEFAULT 0,
    total_spots INTEGER DEFAULT 0,
    filled_spots INTEGER DEFAULT 0,
    prize_pool REAL DEFAULT 0,
    category TEXT,
    is_guaranteed BOOLEAN DEFAULT 0,
    is_flexible BOOLEAN DEFAULT 0,
    winning_breakdown TEXT,          -- JSON string mapping ranks to prizes
    status TEXT DEFAULT 'Upcoming',  -- Upcoming, Live, Completed
    created_at INTEGER NOT NULL,
    FOREIGN KEY (match_id) REFERENCES matches(id)
);
CREATE INDEX IF NOT EXISTS idx_contests_match ON contests(match_id);

-- 12. Teams Table (D1-Only)
CREATE TABLE IF NOT EXISTS teams (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    match_id INTEGER NOT NULL,
    team_name TEXT DEFAULT 'My Team',
    players_json TEXT NOT NULL,      -- JSON array of player objects
    captain_id TEXT,
    vice_captain_id TEXT,
    total_points REAL DEFAULT 0,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (match_id) REFERENCES matches(id)
);
CREATE INDEX IF NOT EXISTS idx_teams_user_match ON teams(user_id, match_id);

-- 12. Contest Participants (Join link)
CREATE TABLE IF NOT EXISTS contest_participants (
    id TEXT PRIMARY KEY,             -- Unique Entry ID
    contest_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    team_id TEXT NOT NULL,
    match_id INTEGER NOT NULL,
    player_ids TEXT,                 -- Legacy/Audit: Snapshot of players at join
    team_name TEXT,
    joined_at INTEGER NOT NULL,
    FOREIGN KEY (match_id) REFERENCES matches(id)
);
CREATE INDEX IF NOT EXISTS idx_participants_contest ON contest_participants(contest_id);
CREATE INDEX IF NOT EXISTS idx_participants_user ON contest_participants(user_id);

-- 13. Contest Leaderboards (Consolidated JSON for fast reads)
CREATE TABLE IF NOT EXISTS contest_leaderboards (
    contest_id TEXT PRIMARY KEY,
    match_id INTEGER NOT NULL,
    data TEXT,                       -- JSON: [{userId, teamName, points, rank, teamId}]
    last_updated INTEGER NOT NULL
);

-- 14. Payout Requests (Manual Withdrawals)
CREATE TABLE IF NOT EXISTS payout_requests (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    amount REAL NOT NULL,
    method TEXT NOT NULL,           -- UPI, Bank, etc.
    details TEXT,                    -- Account details
    status TEXT DEFAULT 'pending',   -- pending, approved, rejected
    admin_note TEXT,
    created_at INTEGER NOT NULL,
    processed_at INTEGER,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
CREATE INDEX IF NOT EXISTS idx_payout_user ON payout_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_payout_status ON payout_requests(status);
