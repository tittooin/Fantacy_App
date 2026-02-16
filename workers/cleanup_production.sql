-- PRODUCTION PRE-LAUNCH CLEANUP SCRIPT
-- WARNING: This will DELETE all test data generated during Phases 9 & 10.

-- 1. Remove Load Test Participants & Safety Test Participants
DELETE FROM contest_participants 
WHERE user_id LIKE 'load_user_%' 
   OR user_id LIKE 'atomic_%' 
   OR user_id IN ('fatigue_tester', 'user_6');

-- 2. Remove Test Users
DELETE FROM users 
WHERE id LIKE 'load_user_%' 
   OR id LIKE 'atomic_%' 
   OR id IN ('fatigue_tester', 'user_6');

-- 3. Remove Load Test Contests (Linked to dummy matches)
DELETE FROM contests 
WHERE match_id IN ('match_load_1', 'match_load_2', 'match_load_3');

-- 4. Remove Transactions related to Test Users (if transactions table exists)
-- Assuming table name 'transactions' based on workers/index.js
DELETE FROM transactions 
WHERE user_id LIKE 'load_user_%' 
   OR user_id LIKE 'atomic_%' 
   OR user_id IN ('fatigue_tester', 'user_6');

-- 5. Reset Auto-increment triggers (if any) or Sequences?
-- No integer auto-increments used (UUIDs).

-- 6. Verification Query
SELECT count(*) as remaining_test_users FROM users WHERE id LIKE 'load_user_%';
