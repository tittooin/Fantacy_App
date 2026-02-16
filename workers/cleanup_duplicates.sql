-- Clean up duplicates: Keep only the one with the earliest joined_at (or Min ID)

DELETE FROM contest_participants 
WHERE id NOT IN (
    SELECT min(id)
    FROM contest_participants
    GROUP BY contest_id, team_id
);
