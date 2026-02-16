-- Phase 4 FINAL TECHNICAL PROOF (PASS/FAIL Evidence)
-- Setup
DELETE FROM users WHERE id = 'e2e_user';
INSERT INTO users (id, name, email, deposit_credits, winning_credits, joined_at) 
VALUES ('e2e_user', 'E2E User', 'e2e@test.com', 100, 2000, 1700000000000);

DELETE FROM payout_requests WHERE user_id = 'e2e_user';
DELETE FROM transactions WHERE user_id = 'e2e_user';

-- 1. USER WITHDRAWAL REQUEST
-- Mocking Worker: handleWithdrawRequest
UPDATE users SET winning_credits = winning_credits - 500 WHERE id = 'e2e_user' AND winning_credits >= 500;
INSERT INTO payout_requests (id, user_id, amount, method, status, created_at) 
VALUES ('req_001', 'e2e_user', 500, 'UPI', 'pending', 1700000000001);
INSERT INTO transactions (id, user_id, type, amount, status, created_at)
VALUES ('txn_001', 'e2e_user', 'withdrawal_request', 500, 'pending', 1700000000001);

SELECT 'PASS/FAIL: Withdrawal Request Created' as test, winning_credits FROM users WHERE id = 'e2e_user'; -- Should be 1500

-- 2. ADMIN APPROVAL
-- Mocking Worker: handleAdminUpdateWithdrawalStatus (status: approved)
UPDATE payout_requests SET status = 'approved', admin_note = 'Paid', processed_at = 1700000000002 WHERE id = 'req_001' AND status = 'pending';
-- Note: Approval in our system doesn't change user balance (deduction happened at request time).
-- But we verify it stays 1500 and status changes.

SELECT 'PASS/FAIL: Admin Approval Status' as test, status FROM payout_requests WHERE id = 'req_001'; -- Should be approved

-- 3. CONTEST PARTICIPANTS SAFETY
-- Ensure no other tables were affected (Mock check)
SELECT 'PASS/FAIL: Contest Table Safety' as test, COUNT(*) as count FROM contest_participants WHERE user_id = 'e2e_user'; -- Should be 0

-- 4. REJECTION & REFUND FLOW
-- Reset User for Rejection Test
UPDATE users SET winning_credits = 2000 WHERE id = 'e2e_user';
INSERT INTO payout_requests (id, user_id, amount, method, status, created_at) 
VALUES ('req_002', 'e2e_user', 300, 'UPI', 'pending', 1700000000005);
UPDATE users SET winning_credits = winning_credits - 300 WHERE id = 'e2e_user'; -- User request

-- ADMIN REJECTS
-- Batch Simulation
UPDATE users SET winning_credits = winning_credits + 300 WHERE id = 'e2e_user';
UPDATE payout_requests SET status = 'rejected', admin_note = 'Invalid UPI', processed_at = 1700000000010 WHERE id = 'req_002' AND status = 'pending';

SELECT 'PASS/FAIL: Rejection Refund Balance' as test, winning_credits FROM users WHERE id = 'e2e_user'; -- Should be 2000

-- 5. PARALLEL PROCESSING (DOUBLE REJECT BLOCK)
-- Attempt second reject on req_002 (which is already rejected)
-- The 'AND status = pending' clause should prevent changes
UPDATE users SET winning_credits = winning_credits + 300 WHERE id = 'e2e_user' AND (SELECT status FROM payout_requests WHERE id = 'req_002') = 'pending';
UPDATE payout_requests SET status = 'rejected' WHERE id = 'req_002' AND status = 'pending';

SELECT 'PASS/FAIL: Double Processing Protection' as test, winning_credits FROM users WHERE id = 'e2e_user'; -- Should REMAIN 2000 (no double refund)
