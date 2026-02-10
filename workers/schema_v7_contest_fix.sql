-- Migration V7: Fix contests table schema
-- Adding missing columns to match app requirements

ALTER TABLE contests ADD COLUMN prize_pool REAL;
ALTER TABLE contests ADD COLUMN category TEXT;
ALTER TABLE contests ADD COLUMN is_guaranteed INTEGER DEFAULT 0;
ALTER TABLE contests ADD COLUMN is_flexible INTEGER DEFAULT 0;
ALTER TABLE contests ADD COLUMN winning_breakdown TEXT;
