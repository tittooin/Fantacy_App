-- Migration v11: Add Check Constraints for Wallet Balance
-- This ensures that any update causing negative balance triggers a Rollback.

-- SQLite doesn't support ADD CONSTRAINT on existing tables easily.
-- We must check if balance >= 0 in a TRIGGER or (risky) recreate table.
-- Trigger is safer for migration.

CREATE TRIGGER IF NOT EXISTS check_user_balance_update
BEFORE UPDATE OF deposit_credits, winning_credits ON users
FOR EACH ROW
WHEN NEW.deposit_credits < 0 OR NEW.winning_credits < 0
BEGIN
    SELECT RAISE(ROLLBACK, 'INSUFFICIENT_FUNDS');
END;

-- Also upgrade the Contest Overfill Trigger to ROLLBACK
DROP TRIGGER IF EXISTS prevent_contest_overfill;
CREATE TRIGGER prevent_contest_overfill
BEFORE UPDATE OF filled_spots ON contests
FOR EACH ROW
WHEN NEW.filled_spots > NEW.total_spots
BEGIN
    SELECT RAISE(ROLLBACK, 'CONTEST_FULL_TRIGGER');
END;
