-- Schema V3: Add match_id to contest_participants for efficient filtering
-- run: wrangler d1 execute fantasy-db --file=workers/schema_v3_match_id.sql

ALTER TABLE contest_participants ADD COLUMN match_id TEXT;
CREATE INDEX IF NOT EXISTS idx_participants_match ON contest_participants(match_id);
