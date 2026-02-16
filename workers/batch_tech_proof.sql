-- FINAL TECHNICAL PROOF: ATOMIC BATCHING
-- This script simulates the batch logic implemented in the Cloudflare Worker

-- 1. SETUP TEST DATA
DELETE FROM users WHERE id = 'batch_user';
DELETE FROM payout_requests WHERE user_id = 'batch_user';
DELETE FROM voucher_requests WHERE user_id = 'batch_user';
DELETE FROM transactions WHERE user_id = 'batch_user';

INSERT INTO users (id, name, email, winning_credits) VALUES ('batch_user', 'Batch Tester', 'batch@test.com', 5000);

-- 2. VOUCHER REQUEST BATCH TEST
-- Logic: Balance -1000, Insert Req, Insert Txn
UPDATE users SET winning_credits = winning_credits - 1000 WHERE id = 'batch_user' AND winning_credits >= 1000;
INSERT INTO voucher_requests (id, user_id, brand, credits, status, created_at) VALUES ('v_001', 'batch_user', 'BrandA', 1000, 'pending', 123);
INSERT INTO transactions (id, user_id, type, amount, created_at, status) VALUES ('v_001', 'batch_user', 'voucher_request', 1000, 123, 'pending');

SELECT 'STEP 2: Request' as step, winning_credits FROM users WHERE id = 'batch_user'; -- Should be 4000
SELECT status FROM transactions WHERE id = 'v_001'; -- Should be pending

-- 3. VOUCHER REJECT BATCH TEST (Atomic Refund)
-- Logic: Balance +1000, Req status = rejected, Txn status = rejected (Only if current status is pending)
-- We simulate the WHERE check in batch by pre-checking if the request is pending

UPDATE users SET winning_credits = winning_credits + 1000 WHERE id = 'batch_user' AND (SELECT status FROM voucher_requests WHERE id = 'v_001') = 'pending';
UPDATE voucher_requests SET status = 'rejected', approved_at = 456 WHERE id = 'v_001' AND status = 'pending';
UPDATE transactions SET status = 'rejected' WHERE id = 'v_001' AND (SELECT status FROM voucher_requests WHERE id = 'v_001') = 'rejected';

SELECT 'STEP 3: Reject' as step, winning_credits FROM users WHERE id = 'batch_user'; -- Should be 5000 (Refunded)
SELECT status FROM transactions WHERE id = 'v_001'; -- Should be rejected

-- 4. DOUBLE REJECT BLOCK TEST
-- Re-attempting refund on already rejected request
UPDATE users SET winning_credits = winning_credits + 1000 WHERE id = 'batch_user' AND (SELECT status FROM voucher_requests WHERE id = 'v_001') = 'pending';

SELECT 'STEP 4: Double Reject' as step, winning_credits FROM users WHERE id = 'batch_user'; -- Should REMAIN 5000 (No double refund)
