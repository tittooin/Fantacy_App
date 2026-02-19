-- Add event tracking columns to matches table
ALTER TABLE matches ADD COLUMN last_score TEXT;
ALTER TABLE matches ADD COLUMN last_wickets INTEGER;
ALTER TABLE matches ADD COLUMN last_over TEXT;
ALTER TABLE matches ADD COLUMN last_innings INTEGER;
