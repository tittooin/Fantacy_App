-- Recreate match_squads table to ensure all columns exist
DROP TABLE IF EXISTS match_squads;
CREATE TABLE match_squads (
    match_id TEXT PRIMARY KEY,
    series_id INTEGER,
    team_a_roster JSON, -- Array of players
    team_b_roster JSON, -- Array of players
    playing_11_a JSON, -- Array of IDs
    playing_11_b JSON, -- Array of IDs
    last_updated INTEGER
);
