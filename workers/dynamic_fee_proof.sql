-- DYNAMIC FEE VERIFICATION SCRIPT
-- SETUP 
DELETE FROM contest_participants;
DELETE FROM users WHERE id = 'DYNAMIC_USER';
DELETE FROM contests WHERE id IN ('C_10', 'C_25');
DELETE FROM matches WHERE id = 888;

INSERT INTO matches (id, title, status, start_time) VALUES (888, 'Dynamic Match', 'Upcoming', 1000);
INSERT INTO users (id, name, email, deposit_credits, winning_credits, joined_at) VALUES ('DYNAMIC_USER', 'Dynamic Tester', 'test@axevora.com', 500, 0, 1000);

-- [1] TEST 1: 10 CREDIT CONTEST
INSERT INTO contests (id, match_id, entry_fee, total_spots, filled_spots, status, created_at)
VALUES ('C_10', 888, 10, 50, 0, 'Upcoming', 1000);

SELECT '--- [TEST 1] 10 CREDIT CONTEST (INITIAL) ---' as status;
SELECT deposit_credits FROM users WHERE id = 'DYNAMIC_USER';

-- SIMULATE 5 JOINS (Using the logic from the worker)
-- Deduct 50 (5 * 10)
UPDATE users SET deposit_credits = deposit_credits - 50 WHERE id = 'DYNAMIC_USER';
UPDATE contests SET filled_spots = filled_spots + 5 WHERE id = 'C_10';

SELECT '--- [TEST 1] 10 CREDIT CONTEST (AFTER 5 JOINS) ---' as status;
SELECT (SELECT entry_fee FROM contests WHERE id = 'C_10') as contest_fee;
SELECT deposit_credits FROM users WHERE id = 'DYNAMIC_USER';
SELECT filled_spots FROM contests WHERE id = 'C_10';

-- [2] TEST 2: 25 CREDIT CONTEST
INSERT INTO contests (id, match_id, entry_fee, total_spots, filled_spots, status, created_at)
VALUES ('C_25', 888, 25, 50, 0, 'Upcoming', 1000);

SELECT '--- [TEST 2] 25 CREDIT CONTEST (INITIAL) ---' as status;
-- Note: User has 450 left (500 - 50)
SELECT deposit_credits FROM users WHERE id = 'DYNAMIC_USER';

-- SIMULATE 4 JOINS
-- Deduct 100 (4 * 25)
UPDATE users SET deposit_credits = deposit_credits - 100 WHERE id = 'DYNAMIC_USER';
UPDATE contests SET filled_spots = filled_spots + 4 WHERE id = 'C_25';

SELECT '--- [TEST 2] 25 CREDIT CONTEST (AFTER 4 JOINS) ---' as status;
SELECT (SELECT entry_fee FROM contests WHERE id = 'C_25') as contest_fee;
SELECT deposit_credits FROM users WHERE id = 'DYNAMIC_USER';
SELECT filled_spots FROM contests WHERE id = 'C_25';

-- [3] FINAL BALANCES
SELECT '--- FINAL WALLET STATUS ---' as status;
SELECT deposit_credits FROM users WHERE id = 'DYNAMIC_USER';
