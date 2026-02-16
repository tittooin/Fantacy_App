-- CLEANUP STALE LIVE MATCHES
-- Matches marked as 'Live' but started > 15 hours ago should be 'Completed'
-- This stops the Points Engine from polling them forever.

UPDATE matches 
SET status = 'Completed' 
WHERE status = 'Live' 
AND start_time < (strftime('%s', 'now') * 1000 - (15 * 60 * 60 * 1000));

-- Verify
SELECT id, title, status, start_time FROM matches WHERE status = 'Completed' ORDER BY start_time DESC LIMIT 5;
