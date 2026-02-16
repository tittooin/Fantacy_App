INSERT INTO matches (id, team_a, team_b, team_a_id, team_b_id, status, start_time, series_id) 
VALUES ('999999', 'Test Team A', 'Test Team B', '100', '200', 'Upcoming', 1999999999999, '7688')
ON CONFLICT(id) DO NOTHING;

INSERT INTO match_squads (match_id, team_a_roster, team_b_roster, squad_state, last_updated)
VALUES (
    '999999', 
    '[{"id":"p1","name":"Bowler One","role":"BOWL"},{"id":"p2","name":"Keeper One","role":"WK"},{"id":"p3","name":"Batter One","role":"BAT"},{"id":"p4","name":"All Rounder","role":"AR"}]',
    '[{"id":"p5","name":"Batter Two","role":"BAT"}]',
    1, 
    1771161938948
)
ON CONFLICT(match_id) DO UPDATE SET team_a_roster = excluded.team_a_roster;
