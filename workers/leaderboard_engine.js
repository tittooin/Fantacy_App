export async function processLeaderboards(env) {
    console.log("Starting Leaderboard Calculation Cycle (Optimized)...");

    try {
        // OPTIMIZATION 1: Strict Live Check + Recent Completion (Finalize)
        // We only process matches that are LIVE or completed recently (e.g. within 20 mins to ensure final calc)
        // D1 Query: status = 'Live' OR (status = 'Completed' AND last_updated > ?)

        const recentCutoff = Date.now() - (20 * 60 * 1000); // 20 mins ago

        const { results: activeMatches } = await env.DB.prepare(
            `SELECT id, status, last_updated FROM matches 
             WHERE status = 'Live' 
             OR (status = 'Completed' AND last_updated > ?)`
        ).bind(recentCutoff).all();

        if (!activeMatches || activeMatches.length === 0) {
            console.log("No active matches to process.");
            return;
        }

        for (const match of activeMatches) {
            // OPTIMIZATION 2: Check if points actually changed?
            // This requires storing 'last_calc_hash' or similar. 
            // For MVP, we rely on the restricted query above. 
            // If it's Live, we assume points change.
            await calculateLeaderboardForMatch(env, match.id);
        }

    } catch (e) {
        console.error("Leaderboard Cycle Error:", e);
    }
}

async function calculateLeaderboardForMatch(env, matchId) {
    console.log(`Calculating for Match: ${matchId}`);

    // 1. Get Player Points
    const { results: pointRows } = await env.DB.prepare(
        "SELECT player_id, points FROM fantasy_points WHERE match_id = ?"
    ).bind(matchId).all();

    const pointsMap = {}; // player_id -> points
    pointRows.forEach(r => pointsMap[r.player_id] = (r.points || 0));

    // 2. Get Participants for this Match
    const { results: participants } = await env.DB.prepare(
        "SELECT contest_id, user_id, team_name, player_ids, team_id FROM contest_participants WHERE match_id = ?"
    ).bind(matchId).all();

    if (!participants || participants.length === 0) return;

    // Group by Contest
    const contestGroups = {};
    for (const p of participants) {
        if (!contestGroups[p.contest_id]) contestGroups[p.contest_id] = [];
        contestGroups[p.contest_id].push(p);
    }

    // 3. Process Each Contest
    const stmt = env.DB.prepare(
        "INSERT OR REPLACE INTO contest_leaderboards (contest_id, match_id, data, last_updated) VALUES (?, ?, ?, ?)"
    );

    const batch = [];

    for (const contestId in contestGroups) {
        const entries = contestGroups[contestId];

        // Calc Scores
        const leaderboard = entries.map(entry => {
            let total = 0;
            let pIds = [];
            try {
                pIds = JSON.parse(entry.player_ids || '[]');
            } catch (e) { pIds = []; }

            pIds.forEach(pid => {
                total += (pointsMap[pid] || 0);
            });

            return {
                userId: entry.user_id,
                teamName: entry.team_name,
                points: total,
                teamId: entry.team_id
            };
        });

        // Sort
        leaderboard.sort((a, b) => b.points - a.points);

        // Assign Ranks
        // Handle ties? Simple dense rank or row number?
        // Simple Row Number for MVP, handling ties visually UI side if needed, or 
        // Standard competition ranking: 1, 2, 2, 4...

        let rank = 1;
        for (let i = 0; i < leaderboard.length; i++) {
            if (i > 0 && leaderboard[i].points < leaderboard[i - 1].points) {
                rank = i + 1;
            }
            leaderboard[i].rank = rank;
        }

        // Add to Batch
        batch.push(stmt.bind(
            contestId,
            matchId,
            JSON.stringify(leaderboard),
            Date.now()
        ));
    }

    // Execute Batch Write
    if (batch.length > 0) {
        // D1 Batch limit is usually high enough, but good to chunk if massive.
        // Assuming reasonable number of contests per match.
        await env.DB.batch(batch);
        console.log(`Updated ${batch.length} contests for Match ${matchId}`);
    }
}
