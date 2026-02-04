-- Migration v5: Add Team IDs to Matches table for robust Squad Fallback
ALTER TABLE matches ADD COLUMN team_a_id INTEGER;
ALTER TABLE matches ADD COLUMN team_b_id INTEGER;
