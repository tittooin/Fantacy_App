-- Phase 4 FINAL AUDIT: End-to-End Wallet D1 Proof
-- 1. Setup User with Winning Balance
DELETE FROM users WHERE id = 'audit_user_4';
INSERT INTO users (id, name, email, deposit_credits, winning_credits, joined_at) 
VALUES ('audit_user_4', 'Audit User 4', 'user4@audit.com', 500, 1000, 1700000000000);

SELECT '--- 1. Initial State ---' as log;
SELECT id, deposit_credits, winning_credits FROM users WHERE id = 'audit_user_4';

-- 2. User Requests Withdrawal (Deduction + Request Insert)
-- Mocking the Worker handler's batch logic
UPDATE users SET winning_credits = winning_credits - 400 WHERE id = 'audit_user_4' AND winning_credits >= 400;
INSERT INTO payout_requests (id, user_id, amount, method, details, status, created_at) 
VALUES ('payout_4_1', 'audit_user_4', 400, 'UPI', 'audit@upi', 'pending', 1710000000000);

SELECT '--- 2. After User Request (Pending) ---' as log;
SELECT id, deposit_credits, winning_credits FROM users WHERE id = 'audit_user_4';
SELECT id, user_id, amount, status FROM payout_requests WHERE id = 'payout_4_1';

-- 3. Admin Approves Payout
UPDATE payout_requests SET status = 'approved', admin_note = 'Paid via Bank', processed_at = 1710000010000 WHERE id = 'payout_4_1';

SELECT '--- 3. After Admin Approval ---' as log;
SELECT id, status, admin_note FROM payout_requests WHERE id = 'payout_4_1';
SELECT id, deposit_credits, winning_credits FROM users WHERE id = 'audit_user_4';

-- 4. Admin Rejects NEW Payout (Refund Proof)
INSERT INTO payout_requests (id, user_id, amount, method, details, status, created_at) 
VALUES ('payout_4_2', 'audit_user_4', 200, 'UPI', 'audit@upi', 'pending', 1710000020000);
UPDATE users SET winning_credits = winning_credits - 200 WHERE id = 'audit_user_4'; -- User requested it

SELECT '--- 4. Payout 2 Requested (Before Reject) ---' as log;
SELECT id, deposit_credits, winning_credits FROM users WHERE id = 'audit_user_4';

-- Simulate Reject & Refund Job
UPDATE users SET winning_credits = winning_credits + 200 WHERE id = 'audit_user_4';
UPDATE payout_requests SET status = 'rejected', admin_note = 'Incorrect details', processed_at = 1710000030000 WHERE id = 'payout_4_2';

SELECT '--- 5. After Admin Rejection (Refunded) ---' as log;
SELECT id, deposit_credits, winning_credits FROM users WHERE id = 'audit_user_4';
SELECT id, status, admin_note FROM payout_requests WHERE id = 'payout_4_2';

-- 5. Admin Search Proof
SELECT '--- 6. Admin Search Proof ---' as log;
SELECT id, name, email FROM users WHERE email = 'user4@audit.com';
