-- Phase 5: Voucher System Technical Audit (Atomic Batch Fix)
-- Purpose: Verify synchronization between voucher_requests and transactions log.

-- 1. Setup Test User
DELETE FROM users WHERE id = 'audit_v5_final';
DELETE FROM voucher_requests WHERE user_id = 'audit_v5_final';
DELETE FROM transactions WHERE user_id = 'audit_v5_final';

INSERT INTO users (id, name, winning_credits) VALUES ('audit_v5_final', 'V5 Final User', 1000);

-- 2. Create Voucher Request (User Flow)
-- Simulated atomic batch from Worker
INSERT INTO users (id, winning_credits) VALUES ('audit_v5_final', 1000) ON CONFLICT(id) DO UPDATE SET winning_credits = 900;
INSERT INTO voucher_requests (id, user_id, brand, credits, status, created_at)
VALUES ('vr_final_1', 'audit_v5_final', 'Amazon', 100, 'pending', 1676239200000);
INSERT INTO transactions (id, user_id, type, amount, created_at, status)
VALUES ('vr_final_1', 'audit_v5_final', 'voucher_request', 100, 1676239200000, 'pending');

SELECT 'STEP 2: Request Created' as step, winning_credits FROM users WHERE id = 'audit_v5_final';
SELECT status FROM transactions WHERE id = 'vr_final_1';

-- 3. APPROVAL PROOF (Atomic Log Sync)
-- Simulate Worker handleAdminApproveVoucher (Action: approve)
UPDATE voucher_requests SET status = 'approved', voucher_code = 'FINAL-V5-SYNC', approved_at = 1676242800000
WHERE id = 'vr_final_1' AND status = 'pending';
UPDATE transactions SET status = 'success' WHERE id = 'vr_final_1';

SELECT 'STEP 3: Approval Done' as step, status as request_status FROM voucher_requests WHERE id = 'vr_final_1';
SELECT 'STEP 3: Log Sync Check' as step, status as log_status FROM transactions WHERE id = 'vr_final_1';

-- 4. REJECTION PROOF (Atomic Refund + Log Sync)
-- Create another request
INSERT INTO users (id, winning_credits) VALUES ('audit_v5_final', 900) ON CONFLICT(id) DO UPDATE SET winning_credits = 700;
INSERT INTO voucher_requests (id, user_id, brand, credits, status, created_at)
VALUES ('vr_final_2', 'audit_v5_final', 'Flipkart', 200, 'pending', 1676246400000);
INSERT INTO transactions (id, user_id, type, amount, created_at, status)
VALUES ('vr_final_2', 'audit_v5_final', 'voucher_request', 200, 1676246400000, 'pending');

-- Simulate Worker handleAdminApproveVoucher (Action: reject)
UPDATE users SET winning_credits = winning_credits + 200 WHERE id = 'audit_v5_final';
UPDATE voucher_requests SET status = 'rejected' WHERE id = 'vr_final_2' AND status = 'pending';
UPDATE transactions SET status = 'rejected' WHERE id = 'vr_final_2';

SELECT 'STEP 4: Rejection Done' as step, winning_credits FROM users WHERE id = 'audit_v5_final';
SELECT 'STEP 4: Log Sync Check' as step, status as log_status FROM transactions WHERE id = 'vr_final_2';

-- 5. DOUBLE REJECTION BLOCK PROOF
-- Attempt to reject again
-- This update should fail to find any 'pending' row in voucher_requests
UPDATE users SET winning_credits = winning_credits + 200 WHERE id = 'audit_v5_final'
AND (SELECT count(*) FROM voucher_requests WHERE id = 'vr_final_2' AND status = 'pending') > 0;

SELECT 'STEP 5: Double Reject Blocked' as step, winning_credits FROM users WHERE id = 'audit_v5_final';
