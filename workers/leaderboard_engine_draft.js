export async function processLeaderboards(env) {
    console.log("Starting Leaderboard Calculation Cycle...");

    try {
        // 1. Find ACTIVE matches (Live or Recently Completed)
        // Ideally we query D1 matches, but for now we can rely on Contest status if synced, 
        // OR easier: Get all 'Live' matches from D1 matches table.
        // Assuming we have 'matches' table in D1 as per Phase 1. 

        const { results: activeMatches } = await env.DB.prepare(
            "SELECT id FROM matches WHERE status = 'Live' OR status = 'Completed'"
            // Note: We might want to filter Completed to only those needing final calc. 
            // For now, simplicity: Process all Live.
        ).all();

        if (!activeMatches || activeMatches.length === 0) {
            console.log("No active matches for leaderboard.");
            return;
        }

        for (const match of activeMatches) {
            await calculateForMatch(env, match.id);
        }

    } catch (e) {
        console.error("Leaderboard Process Error:", e);
    }
}

async function calculateForMatch(env, matchId) {
    // 2. Get Match Points Mapping: PlayerID -> Points
    const { results: pointsRows } = await env.DB.prepare(
        "SELECT player_id, total_points FROM fantasy_points WHERE match_id = ?"
    ).bind(matchId).all();

    if (!pointsRows || pointsRows.length === 0) {
        console.log(`No points found for match ${matchId}`);
        return;
    }

    const pointsMap = {};
    for (const row of pointsRows) {
        pointsMap[row.player_id] = row.total_points || 0;
    }

    // 3. Find Contests for this Match
    // We need to know which contests are for this match.
    // We can query contest_participants joined with something? 
    // Or just query participants where contest_id IN (SELECT id FROM contests WHERE match_id = matchId) if we had a contests table in D1.
    // If Contests table isn't in D1 yet, we might rely on naming convention or a separate sync.
    // FALLBACK: Query Distinct contest_id from contest_participants.
    // Optimization: We really should have a 'contests' table in D1. 
    // If not, we iterate ALL participants (expensive).
    // Let's assume we iterate all contests present in 'contest_participants' (this table grows, so we need a match_id filter).
    // WAITING: If we don't have match_id in contest_participants, we can't filter easily.
    // FIX: Add 'match_id' to contest_participants in Schema? 
    // TOO LATE for Schema change in this file step. 
    // Alternative: We can pass matchId loop.

    // Better Approach: 
    // We fetch ALL distinct contest_ids that have participants.
    // Then for earch contest, we check if it belongs to this match? 
    // No, that's slow.

    // Correction: We rely on the fact that we should sync "Contest Metadata" to D1 or just `contest_participants`.
    // Let's assume for now we scan ALL contests in `contest_participants` table.
    // Since we don't have match_id column there, this is inefficient.
    // BUT the user accepted the plan.
    // Let's optimize: We will query "SELECT DISTINCT contest_id FROM contest_participants".
    // Wait, that scans everything.

    // User Requirement: "Contest participants ka data D1 me sync karo".
    // Let's assume we just iterate all for now (MVP). 
    // Or we iterate known live matches' contests if we had that mapping.

    // Let's try to grab contests from Firestore? NO, Zero Firestore Reads.
    // OK, we will add a 'match_id' column to 'contest_participants' in the next schema update or just ignore valid filter for now and calc all?
    // No, calculating invalid contests (wrong match) with points map of a different match is bad.

    // TRICK: We can just JOIN if we had a matches table.
    // Let's look at `contest_participants` again.
    // contest_id, user_id, team_id, player_ids, team_name.

    // We need to know which Match this contest belongs to.
    // Let's fetch Contest Details from Firestore? NO.
    // Let's fetch from D1 'contests' table if it exists?
    // Checking previous steps... Phase 1 "Design SQL Schema: Matches, Players...". Did we create Contests?
    // Likely not.

    // CRITICAL FIX: We need `match_id` in `contest_participants` to group them correctly.
    // I will use `match_id` which acts as a partition.
    // I will assume the table has `match_id`. If I didn't add it in V2, I messed up.
    // Checking V2: `CREATE TABLE IF NOT EXISTS contest_participants (contest_id TEXT NOT NULL, ...)` -> NO match_id.

    // OK, I must add `match_id` to `contest_participants`.
    // I will do a quick ALTER TABLE or DROP/CREATE since it's empty.

    // ... WAIT, I can run another migration immediately.
}
