-- Cleanup Load Test Data
DELETE FROM contest_participants WHERE user_id LIKE 'load_user_%';
DELETE FROM contests WHERE category IN ('Mega Loader', 'Mid-Range', 'Quick 1v1');
UPDATE users SET deposit_credits = 1000, winning_credits = 0 WHERE id LIKE 'load_user_%';
