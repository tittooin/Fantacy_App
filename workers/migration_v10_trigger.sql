-- Migration v10: Constraint to prevent overfilling contests (Safety Net)
-- This ensures that ANY update that pushes filled_spots > total_spots triggers a Rollback.

CREATE TRIGGER IF NOT EXISTS prevent_contest_overfill
BEFORE UPDATE OF filled_spots ON contests
FOR EACH ROW
WHEN NEW.filled_spots > NEW.total_spots
BEGIN
    SELECT RAISE(ABORT, 'CONTEST_FULL_TRIGGER');
END;
