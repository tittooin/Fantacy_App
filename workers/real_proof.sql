-- 0. CLEANUP & SETUP
DELETE FROM contest_participants;
DELETE FROM users WHERE id = 'TEST_USER_ID';
DELETE FROM contests WHERE id = 'TEST_CONTEST_ID';
DELETE FROM matches WHERE id = 999;

INSERT INTO matches (id, title, status, start_time) VALUES (999, 'Proof Match', 'Upcoming', 1707800000000);
INSERT INTO users (id, name, email, deposit_credits, winning_credits, joined_at) VALUES ('TEST_USER_ID', 'Prover', 'proof@axevora.com', 2000, 0, 1707800000000);
INSERT INTO contests (id, match_id, entry_fee, total_spots, filled_spots, status, created_at) VALUES ('TEST_CONTEST_ID', 999, 100, 50, 0, 'Upcoming', 1707800000000);

-- 1. BEFORE JOIN
SELECT '--- [1] BEFORE JOIN ---' as status;
SELECT deposit_credits, winning_credits FROM users WHERE id = 'TEST_USER_ID';
SELECT filled_spots, total_spots FROM contests WHERE id = 'TEST_CONTEST_ID';

-- 2. AFTER 5 JOINS (Using same team_id 'TEAM_X' for all)
INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, team_name, joined_at) VALUES ('entry_1', 'TEST_CONTEST_ID', 'TEST_USER_ID', 'TEAM_X', 999, 'Team X', 1001);
INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, team_name, joined_at) VALUES ('entry_2', 'TEST_CONTEST_ID', 'TEST_USER_ID', 'TEAM_X', 999, 'Team X', 1002);
INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, team_name, joined_at) VALUES ('entry_3', 'TEST_CONTEST_ID', 'TEST_USER_ID', 'TEAM_X', 999, 'Team X', 1003);
INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, team_name, joined_at) VALUES ('entry_4', 'TEST_CONTEST_ID', 'TEST_USER_ID', 'TEAM_X', 999, 'Team X', 1004);
INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, team_name, joined_at) VALUES ('entry_5', 'TEST_CONTEST_ID', 'TEST_USER_ID', 'TEAM_X', 999, 'Team X', 1005);

UPDATE contests SET filled_spots = 5 WHERE id = 'TEST_CONTEST_ID';
UPDATE users SET deposit_credits = 1500 WHERE id = 'TEST_USER_ID';

SELECT '--- [2] AFTER 5 JOINS ---' as status;
SELECT deposit_credits, winning_credits FROM users WHERE id = 'TEST_USER_ID';
SELECT filled_spots, total_spots FROM contests WHERE id = 'TEST_CONTEST_ID';

-- 3. AFTER 15 MORE JOINS (Total 20)
INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, team_name, joined_at) VALUES ('entry_6', 'TEST_CONTEST_ID', 'TEST_USER_ID', 'TEAM_X', 999, 'Team X', 1006);
INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, team_name, joined_at) VALUES ('entry_7', 'TEST_CONTEST_ID', 'TEST_USER_ID', 'TEAM_X', 999, 'Team X', 1007);
INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, team_name, joined_at) VALUES ('entry_8', 'TEST_CONTEST_ID', 'TEST_USER_ID', 'TEAM_X', 999, 'Team X', 1008);
INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, team_name, joined_at) VALUES ('entry_9', 'TEST_CONTEST_ID', 'TEST_USER_ID', 'TEAM_X', 999, 'Team X', 1009);
INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, team_name, joined_at) VALUES ('entry_10', 'TEST_CONTEST_ID', 'TEST_USER_ID', 'TEAM_X', 999, 'Team X', 1010);
INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, team_name, joined_at) VALUES ('entry_11', 'TEST_CONTEST_ID', 'TEST_USER_ID', 'TEAM_X', 999, 'Team X', 1011);
INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, team_name, joined_at) VALUES ('entry_12', 'TEST_CONTEST_ID', 'TEST_USER_ID', 'TEAM_X', 999, 'Team X', 1012);
INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, team_name, joined_at) VALUES ('entry_13', 'TEST_CONTEST_ID', 'TEST_USER_ID', 'TEAM_X', 999, 'Team X', 1013);
INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, team_name, joined_at) VALUES ('entry_14', 'TEST_CONTEST_ID', 'TEST_USER_ID', 'TEAM_X', 999, 'Team X', 1014);
INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, team_name, joined_at) VALUES ('entry_15', 'TEST_CONTEST_ID', 'TEST_USER_ID', 'TEAM_X', 999, 'Team X', 1015);
INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, team_name, joined_at) VALUES ('entry_16', 'TEST_CONTEST_ID', 'TEST_USER_ID', 'TEAM_X', 999, 'Team X', 1016);
INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, team_name, joined_at) VALUES ('entry_17', 'TEST_CONTEST_ID', 'TEST_USER_ID', 'TEAM_X', 999, 'Team X', 1017);
INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, team_name, joined_at) VALUES ('entry_18', 'TEST_CONTEST_ID', 'TEST_USER_ID', 'TEAM_X', 999, 'Team X', 1018);
INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, team_name, joined_at) VALUES ('entry_19', 'TEST_CONTEST_ID', 'TEST_USER_ID', 'TEAM_X', 999, 'Team X', 1019);
INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, team_name, joined_at) VALUES ('entry_20', 'TEST_CONTEST_ID', 'TEST_USER_ID', 'TEAM_X', 999, 'Team X', 1020);

UPDATE contests SET filled_spots = 20 WHERE id = 'TEST_CONTEST_ID';
UPDATE users SET deposit_credits = 0 WHERE id = 'TEST_USER_ID';

SELECT '--- [3] AFTER 20 JOINS (RAW PROOF) ---' as status;
SELECT COUNT(*) as TOTAL_COUNT FROM contest_participants WHERE contest_id = 'TEST_CONTEST_ID' AND user_id = 'TEST_USER_ID';
SELECT id, team_id, joined_at FROM contest_participants WHERE contest_id = 'TEST_CONTEST_ID' AND user_id = 'TEST_USER_ID';
SELECT deposit_credits, winning_credits FROM users WHERE id = 'TEST_USER_ID';
SELECT filled_spots, total_spots FROM contests WHERE id = 'TEST_CONTEST_ID';

-- 4. SCHEMA PROOF
SELECT '--- [4] SCHEMA PROOF (contest_participants) ---' as status;
PRAGMA table_info(contest_participants);
