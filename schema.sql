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

-- 6. Social Rooms (New Architecture)
CREATE TABLE IF NOT EXISTS social_rooms (
    id TEXT PRIMARY KEY,             -- Unique Room ID
    match_id INTEGER NOT NULL,
    host_id TEXT NOT NULL,           -- User who created the room
    room_type TEXT DEFAULT 'public', -- 'public' or 'private'
    title TEXT NOT NULL,             -- E.g. "Global Discussion", "Rahul's Lounge"
    description TEXT,                -- Host Benefits Info / Rules
    max_capacity INTEGER DEFAULT 10000,
    active_members INTEGER DEFAULT 0,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (match_id) REFERENCES matches(id)
);
CREATE INDEX IF NOT EXISTS idx_rooms_match ON social_rooms(match_id);

-- 7. Room Members
CREATE TABLE IF NOT EXISTS room_members (
    room_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    role TEXT DEFAULT 'participant', -- 'host', 'moderator', 'participant', 'viewer'
    joined_at INTEGER NOT NULL,
    PRIMARY KEY (room_id, user_id),
    FOREIGN KEY (room_id) REFERENCES social_rooms(id)
);

-- 8. Users Table (Simplified Profile)
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    name TEXT,
    email TEXT,
    photo_url TEXT,
    access_credits INTEGER DEFAULT 0, -- Virtual Goods/Passes ONLY (No withdraw)
    joined_at INTEGER,
    last_active INTEGER,
    is_restricted BOOLEAN DEFAULT 0
);

-- 9. Chat Messages (D1 Batched)
CREATE TABLE IF NOT EXISTS chat_messages (
    id TEXT PRIMARY KEY,
    room_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    message_type TEXT DEFAULT 'text', -- 'text', 'sound', 'poll'
    content TEXT,                     -- Payload ("Hello", "dhol_sound1", etc)
    created_at INTEGER NOT NULL,
    FOREIGN KEY (room_id) REFERENCES social_rooms(id)
);
CREATE INDEX IF NOT EXISTS idx_chat_room_time ON chat_messages(room_id, created_at);

-- 10. Teams Table (For Interaction Points Only)
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


