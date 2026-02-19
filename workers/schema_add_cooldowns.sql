-- Add dedicated cooldown columns to match_squads table
-- Run this using: npx wrangler d1 execute fantasy-db --file=workers/schema_add_cooldowns.sql

ALTER TABLE match_squads ADD COLUMN series_last_fetch INTEGER;
ALTER TABLE match_squads ADD COLUMN series_last_fail INTEGER;
ALTER TABLE match_squads ADD COLUMN scard_last_fetch INTEGER;
