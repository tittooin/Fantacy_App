-- Migration v6: Allowed Series (White-listing)
CREATE TABLE IF NOT EXISTS allowed_series (
    series_id INTEGER PRIMARY KEY,
    description TEXT,
    created_at INTEGER
);

-- Seed with known active series (e.g., Pakistan vs Ireland T20)
-- ID obtained from previous debug: 11515
INSERT INTO allowed_series (series_id, description, created_at) VALUES (11515, 'PAK vs IRE T20 Series', 1770200000000);
