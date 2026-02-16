-- 0. Clear tables
DELETE FROM contest_participants;
DELETE FROM users WHERE id = 'test_user_001';
DELETE FROM contests WHERE id = 'test_contest_001';
DELETE FROM matches WHERE id = 12345;

-- 1. Setup Test Data
INSERT INTO matches (id, title, status, start_time)
VALUES (12345, 'Test Match', 'Upcoming', 1707800000000);

INSERT INTO users (id, name, email, deposit_credits, winning_credits, joined_at)
VALUES ('test_user_001', 'Test User', 'test@example.com', 1000, 0, 1707800000000);

INSERT INTO contests (id, match_id, entry_fee, total_spots, filled_spots, status, created_at)
VALUES ('test_contest_001', 12345, 50, 20, 0, 'Upcoming', 1707800000000);

-- 2. Verify Initial State
SELECT '--- Initial State ---' as label;
SELECT id, deposit_credits FROM users WHERE id = 'test_user_001';
SELECT id, filled_spots FROM contests WHERE id = 'test_contest_001';

-- 3. Simulate 5 Joins
INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, team_name, joined_at)
VALUES ('p1', 'test_contest_001', 'test_user_001', 'team_alpha', 12345, 'Team Alpha', 1707800000001);
UPDATE contests SET filled_spots = filled_spots + 1 WHERE id = 'test_contest_001';
UPDATE users SET deposit_credits = deposit_credits - 50 WHERE id = 'test_user_001';

INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, team_name, joined_at)
VALUES ('p2', 'test_contest_001', 'test_user_001', 'team_alpha', 12345, 'Team Alpha', 1707800000002);
UPDATE contests SET filled_spots = filled_spots + 1 WHERE id = 'test_contest_001';
UPDATE users SET deposit_credits = deposit_credits - 50 WHERE id = 'test_user_001';

INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, team_name, joined_at)
VALUES ('p3', 'test_contest_001', 'test_user_001', 'team_alpha', 12345, 'Team Alpha', 1707800000003);
UPDATE contests SET filled_spots = filled_spots + 1 WHERE id = 'test_contest_001';
UPDATE users SET deposit_credits = deposit_credits - 50 WHERE id = 'test_user_001';

INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, team_name, joined_at)
VALUES ('p4', 'test_contest_001', 'test_user_001', 'team_alpha', 12345, 'Team Alpha', 1707800000004);
UPDATE contests SET filled_spots = filled_spots + 1 WHERE id = 'test_contest_001';
UPDATE users SET deposit_credits = deposit_credits - 50 WHERE id = 'test_user_001';

INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, team_name, joined_at)
VALUES ('p5', 'test_contest_001', 'test_user_001', 'team_alpha', 12345, 'Team Alpha', 1707800000005);
UPDATE contests SET filled_spots = filled_spots + 1 WHERE id = 'test_contest_001';
UPDATE users SET deposit_credits = deposit_credits - 50 WHERE id = 'test_user_001';

-- 4. Verify 5 Joins
SELECT '--- After 5 Joins ---' as label;
SELECT COUNT(*) as join_count FROM contest_participants WHERE contest_id = 'test_contest_001' AND user_id = 'test_user_001';
SELECT COUNT(DISTINCT id) as unique_id_count FROM contest_participants;
SELECT deposit_credits FROM users WHERE id = 'test_user_001';
SELECT filled_spots FROM contests WHERE id = 'test_contest_001';

-- 5. Simulate 15 more joins (Completing 20)
UPDATE users SET deposit_credits = deposit_credits - (15 * 50) WHERE id = 'test_user_001';
UPDATE contests SET filled_spots = filled_spots + 15 WHERE id = 'test_contest_001';

-- 6. Verify 20 Joins
SELECT '--- After 20 Joins ---' as label;
SELECT deposit_credits FROM users WHERE id = 'test_user_001';
SELECT filled_spots FROM contests WHERE id = 'test_contest_001';

-- 7. Rule Checks
SELECT 
    CASE WHEN (SELECT COUNT(*) FROM contest_participants WHERE contest_id = 'test_contest_001' AND user_id = 'test_user_001') + 15 >= 20 
    THEN 'LIMIT_EXCEEDED_20_TEAMS' ELSE 'PROCEED' END as limit_check;

SELECT 
    CASE WHEN (SELECT filled_spots FROM contests WHERE id = 'test_contest_001') >= (SELECT total_spots FROM contests WHERE id = 'test_contest_001') 
    THEN 'CONTEST_FULL' ELSE 'PROCEED' END as capacity_check;
