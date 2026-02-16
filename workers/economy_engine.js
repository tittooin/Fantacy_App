/**
 * Economy Engine (Phase 9 - Safe Mode)
 * Automatically generates contests for Upcoming matches.
 * 
 * STRICT RULES:
 * 1. Creation Only: Never updates prize_pool or winning_breakdown.
 * 2. Idempotent: Checks if contest exists for (MatchID + EntryFee) before creating.
 * 3. Traffic Unlock: Only unlocks higher tiers when previous tier is >50% full.
 * 4. No Loss: Payouts are calculated runtime by downstream systems.
 */

export async function processEconomy(env) {
    console.log("🏭 Economy Engine Triggered");

    try {
        // 1. Get Upcoming Matches from D1
        // We use the existing 'matches' table
        const { results: upcomingMatches } = await env.DB.prepare(
            "SELECT id, title, start_time FROM matches WHERE status = 'Upcoming'"
        ).all();

        console.log(`🔍 Found ${upcomingMatches.length} upcoming matches.`);

        for (const match of upcomingMatches) {
            await initializeMatch(env, match);
            await monitorTraffic(env, match.id);
        }

    } catch (e) {
        console.error("❌ Economy Engine Error:", e);
    }
}

/**
 * Ensures initial contests exist for a match.
 * Idempotent: Checks existence before creation.
 */
async function initializeMatch(env, match) {
    const matchId = match.id.toString();

    // Check if we already tracked this match
    // Optimization: Read 'auto_contests' state.
    const state = await env.DB.prepare("SELECT * FROM auto_contests WHERE match_id = ?").bind(matchId).first();

    if (!state) {
        console.log(`🆕 Initializing Economy for Match: ${match.title} (${matchId})`);

        // Tier 1: Entry Level Contests
        // Practice (0 fee), Low (5 fee), Medium (10 fee)
        await createContestIdempotent(env, matchId, 0, 'Practice Arena', 100);
        await createContestIdempotent(env, matchId, 5, 'Starter Contest', 100);
        await createContestIdempotent(env, matchId, 10, 'Head to Head', 2); // 2 spots for H2H

        // Save State
        await env.DB.prepare("INSERT INTO auto_contests (match_id, last_tier_unlocked, created_at) VALUES (?, ?, ?)").bind(matchId, 10, Date.now()).run();
    }
}

/**
 * Monitoring Traffic to Unlock Higher Tiers.
 * Rule: unlock next tier if current highest tier is > 50% full.
 */
async function monitorTraffic(env, matchId) {
    const state = await env.DB.prepare("SELECT * FROM auto_contests WHERE match_id = ?").bind(matchId).first();
    if (!state) return; // Should be initialized first

    let currentTier = state.last_tier_unlocked || 0;

    // Define Tier Ladder
    // 10 -> 29 -> 49
    let nextTierFee = 0;
    let nextTierName = '';
    let nextTierSpots = 100;

    if (currentTier === 10) {
        nextTierFee = 29;
        nextTierName = 'Hot Contest';
    } else if (currentTier === 29) {
        nextTierFee = 49;
        nextTierName = 'Mega Contest';
    } else {
        return; // Max tier reached
    }

    // Check traffic of current highest tier contests
    // We look for ANY contest of currentTier that is > 50% full
    const { results: activeContests } = await env.DB.prepare(
        "SELECT filled_spots, total_spots FROM contests WHERE match_id = ? AND entry_fee = ?"
    ).bind(matchId, currentTier).all();

    let shouldUnlock = false;
    for (const c of activeContests) {
        if (c.total_spots > 0 && (c.filled_spots / c.total_spots) > 0.5) {
            shouldUnlock = true;
            break;
        }
    }

    if (shouldUnlock) {
        console.log(`🚀 Traffic Detected! Unlocking ₹${nextTierFee} for ${matchId}`);
        const success = await createContestIdempotent(env, matchId, nextTierFee, nextTierName, nextTierSpots);

        if (success) {
            await env.DB.prepare("UPDATE auto_contests SET last_tier_unlocked = ? WHERE match_id = ?").bind(nextTierFee, matchId).run();
        }
    }
}

/**
 * Creates a contest ONLY if it doesn't exist for this Match + Fee combination.
 * This guarantees Idempotency.
 */
async function createContestIdempotent(env, matchId, entryFee, category, totalSpots) {
    // 1. CHECK EXISTENCE (Strict: Match + Fee)
    // User Requirement: Check (match_id + entry_fee) existence
    const existing = await env.DB.prepare(
        "SELECT id FROM contests WHERE match_id = ? AND entry_fee = ?"
    ).bind(matchId, entryFee).first();

    if (existing) {
        // console.log(`⏩ Contest already exists: ${category} (₹${entryFee})`);
        return false; // Skipped
    }

    // 2. CREATE (If not exists)
    const contestId = crypto.randomUUID();
    const isPractice = entryFee === 0;

    // Note: prize_pool and winning_breakdown are NULL (Calculated Runtime)
    // entry_fee is stored.

    await env.DB.prepare(`
        INSERT INTO contests (
            id, match_id, entry_fee, total_spots, filled_spots, 
            category, is_guaranteed, is_flexible, 
            status, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
        contestId,
        matchId,
        entryFee,
        totalSpots,
        0, // filled_spots
        category,
        0, // is_guaranteed (False)
        1, // is_flexible (True - important for dynamic pool)
        'Upcoming',
        Date.now()
    ).run();

    console.log(`✅ Created Contest: ${category} (₹${entryFee}) for ${matchId}`);
    return true;
}
