-- PHASE 4 WALLET DEEP AUDIT SCRIPT
-- SESSION SETUP
DELETE FROM users WHERE id = 'AUDIT_USER';
DELETE FROM contests WHERE id = 'AUDIT_CONTEST';
DELETE FROM contest_participants WHERE user_id = 'AUDIT_USER';

INSERT INTO users (id, name, deposit_credits, winning_credits, joined_at) 
VALUES ('AUDIT_USER', 'Audit Tester', 0, 0, 1000);

-- SECTION 1: DEPOSIT LOGIC
SELECT '--- [SECTION 1] DEPOSIT LOGIC ---' as section;
-- Initial
SELECT deposit_credits, winning_credits FROM users WHERE id = 'AUDIT_USER';

-- Deposit 500
UPDATE users SET deposit_credits = deposit_credits + 500 WHERE id = 'AUDIT_USER';
SELECT 'After 500 Deposit:' as status;
SELECT deposit_credits, winning_credits FROM users WHERE id = 'AUDIT_USER';

-- SECTION 2: JOIN DEDUCTION PRIORITY
SELECT '--- [SECTION 2] DEDUCTION PRIORITY ---' as section;
-- Reset state
UPDATE users SET deposit_credits = 100, winning_credits = 50 WHERE id = 'AUDIT_USER';
INSERT INTO contests (id, match_id, entry_fee, total_spots, filled_spots, status, created_at)
VALUES ('AUDIT_CONTEST', 777, 120, 50, 0, 'Upcoming', 1000);

SELECT 'Before Join (Dep: 100, Win: 50, Fee: 120):' as status;
SELECT deposit_credits, winning_credits FROM users WHERE id = 'AUDIT_USER';

-- SIMULATE WORKER LOGIC: Deduct Dep first, then Win
-- Logic: entryFee=120, dep=100 -> deductDep=100, deductWin=20
UPDATE users 
SET deposit_credits = deposit_credits - 100, 
    winning_credits = winning_credits - 20 
WHERE id = 'AUDIT_USER' AND (deposit_credits + winning_credits) >= 120;

SELECT 'After Join (Expected Dep: 0, Win: 30):' as status;
SELECT deposit_credits, winning_credits FROM users WHERE id = 'AUDIT_USER';

-- SECTION 3: INSUFFICIENT BALANCE BLOCK
SELECT '--- [SECTION 3] INSUFFICIENT BLOCK ---' as section;
-- Set state
UPDATE users SET deposit_credits = 10, winning_credits = 5 WHERE id = 'AUDIT_USER';
SELECT 'Before Blocked Join (Dep: 10, Win: 5, Fee: 20):' as status;
SELECT deposit_credits, winning_credits FROM users WHERE id = 'AUDIT_USER';

-- Simulate blocked update (D1 condition fails)
UPDATE users 
SET deposit_credits = deposit_credits - 10, 
    winning_credits = winning_credits - 10 
WHERE id = 'AUDIT_USER' AND (deposit_credits + winning_credits) >= 20;

SELECT 'After Blocked Join (Expected No Change):' as status;
SELECT deposit_credits, winning_credits FROM users WHERE id = 'AUDIT_USER';

-- SECTION 4: WINNING CREDIT ADD FLOW
SELECT '--- [SECTION 4] WINNING CREDIT ADD ---' as section;
-- Reset
UPDATE users SET deposit_credits = 50, winning_credits = 100 WHERE id = 'AUDIT_USER';
SELECT 'Before Winnings (Win: 100):' as status;
SELECT deposit_credits, winning_credits FROM users WHERE id = 'AUDIT_USER';

-- Add 200 winnings
UPDATE users SET winning_credits = winning_credits + 200 WHERE id = 'AUDIT_USER';

SELECT 'After Winnings (Expected Dep: 50, Win: 300):' as status;
SELECT deposit_credits, winning_credits FROM users WHERE id = 'AUDIT_USER';

-- SECTION 5: VOUCHER REDEEM DEDUCTION
SELECT '--- [SECTION 5] VOUCHER REDEEM ---' as section;
-- Reset (Win: 300)
SELECT 'Before Redeem 100 (Win: 300):' as status;
SELECT deposit_credits, winning_credits FROM users WHERE id = 'AUDIT_USER';

-- Redeem 100 (Only from winnings)
UPDATE users SET winning_credits = winning_credits - 100 WHERE id = 'AUDIT_USER' AND winning_credits >= 100;

SELECT 'After Redeem 100 (Expected Win: 200, Dep: 50):' as status;
SELECT deposit_credits, winning_credits FROM users WHERE id = 'AUDIT_USER';

-- TEST CASE 2: Insufficient Winnings
UPDATE users SET deposit_credits = 500, winning_credits = 0 WHERE id = 'AUDIT_USER';
SELECT 'Redeem with Insufficient Winning (Dep: 500, Win: 0, Redeem: 100):' as status;

UPDATE users SET winning_credits = winning_credits - 100 WHERE id = 'AUDIT_USER' AND winning_credits >= 100;

SELECT 'After Blocked Redeem (Expected No Change):' as status;
SELECT deposit_credits, winning_credits FROM users WHERE id = 'AUDIT_USER';

-- SECTION 6: NEGATIVE BALANCE PROTECTION (ATOMIC)
SELECT '--- [SECTION 6] NEGATIVE BALANCE PROTECTION ---' as section;
UPDATE users SET deposit_credits = 50, winning_credits = 0 WHERE id = 'AUDIT_USER';
SELECT 'Initial (Balance: 50):' as status;

-- Try to deduct 60
UPDATE users SET deposit_credits = deposit_credits - 60 WHERE id = 'AUDIT_USER' AND deposit_credits >= 60;

SELECT 'After 60 Deduction Attempt (Expected No Change, No Negative):' as status;
SELECT deposit_credits, winning_credits FROM users WHERE id = 'AUDIT_USER';
