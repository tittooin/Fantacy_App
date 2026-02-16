-- Phase 9.2: Safety Constraints

-- 1. Prevent Ghost Teams: Unique Team per Contest
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_team_contest ON contest_participants(contest_id, team_id);

-- 2. Liquidity Race Protection: One Child Per Contest
-- We need to add parent_id to contests.
ALTER TABLE contests ADD COLUMN parent_id TEXT;

-- 3. Ensure a contest can only be a parent ONCE
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_parent_contest ON contests(parent_id);

-- 4. Verify Schema (Optional comment, not SQL)
-- root contest: parent_id = NULL (Allowed multiple)
-- child contest: parent_id = source_contest_id (Unique)
