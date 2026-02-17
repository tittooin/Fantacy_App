
CREATE TABLE IF NOT EXISTS repair_queue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    match_id INTEGER NOT NULL UNIQUE,
    action TEXT NOT NULL DEFAULT 'squad',
    processed BOOLEAN DEFAULT 0,
    created_at INTEGER
);
CREATE INDEX IF NOT EXISTS idx_repair_processed ON repair_queue(processed);
