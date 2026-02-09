
/**
 * Payout Engine (D1 Core)
 * Automates Winnings Distribution when a Match is Completed.
 * 
 * LOGIC:
 * 1. Read Contests from D1 'contests' table
 * 2. Calculate Winners from D1 'contest_leaderboards'
 * 3. Update 'winning_credits' in D1 'users' table
 * 4. Audit in D1 'transactions' table
 */

export async function processPayoutsForMatch(env, matchId) {
    console.log(`💰 Starting Payout Cycle for Match: ${matchId}`);

    try {
        // 1. Verify Match Status
        const match = await env.DB.prepare("SELECT status FROM matches WHERE id = ?").bind(matchId).first();
        if (!match || (match.status !== 'Completed' && match.status !== 'Finished')) {
            console.log("Match not completed yet. Skipping payouts.");
            return;
        }

        // 2. Get Contests for this Match (D1)
        const { results: contests } = await env.DB.prepare("SELECT * FROM contests WHERE match_id = ?").bind(matchId).all();

        console.log(`Found ${contests.length} contests for match.`);

        for (const contest of contests) {
            if (contest.status === 'Distributed' || contest.status === 'Cancelled') {
                continue;
            }
            await distributePrizes(env, contest);
        }

    } catch (e) {
        console.error(`❌ Payout Error for ${matchId}:`, e);
    }
}

async function distributePrizes(env, contest) {
    const contestId = contest.id;
    // Parse breakdown from JSON string (D1 format)
    const breakdown = parseWinningBreakdown(contest.winning_breakdown || contest.winningBreakdown);

    if (!breakdown || breakdown.length === 0) {
        console.log(`No payout structure for ${contestId}`);
        return;
    }

    console.log(`🧮 Calculating Payouts for Contest ${contestId}...`);

    // 1. Get Final Leaderboard from D1
    const lbRow = await env.DB.prepare("SELECT data FROM contest_leaderboards WHERE contest_id = ?").bind(contestId).first();
    if (!lbRow || !lbRow.data) {
        console.log(`No leaderboard found for ${contestId}. Skipping.`);
        return;
    }

    const leaderboard = JSON.parse(lbRow.data);
    const winners = [];

    // 2. Determine Winners
    for (const entry of leaderboard) {
        const rank = entry.rank;
        const prize = getPrizeForRank(rank, breakdown);

        if (prize > 0) {
            winners.push({
                userId: entry.userId || entry.user_id, // Safety check for field name
                amount: prize,
                rank: rank
            });
        }
    }

    if (winners.length === 0) {
        console.log("No winners found.");
        return; // Mark distributed anyway? No, maybe wait?
    }

    // 3. Execute Payouts (D1 Updates)
    console.log(`💸 Distributing to ${winners.length} winners...`);
    await processD1Payouts(env, winners, contestId);

    // 4. Mark Contest as Distributed
    await env.DB.prepare("UPDATE contests SET status = 'Distributed' WHERE id = ?").bind(contestId).run();

    console.log(`✅ Payouts Complete for ${contestId}`);
}

// --- LOGIC HELPERS ---

function getPrizeForRank(rank, breakdown) {
    for (const tier of breakdown) {
        if (rank >= tier.rankStart && rank <= tier.rankEnd) {
            return tier.amount;
        }
    }
    return 0;
}

function parseWinningBreakdown(field) {
    if (!field) return [];
    try {
        if (typeof field === 'string') return JSON.parse(field);
        return field;
    } catch (e) { return []; }
}

// --- INFRASTRUCTURE HELPERS (D1) ---

async function processD1Payouts(env, winners, contestId) {
    // Process sequentially to be safe with D1 concurrency, or use Batch if simple enough.
    // We update User then Insert Transaction.

    for (const w of winners) {
        const txnId = `win_${contestId}_${w.userId}`;

        try {
            // Transaction-like safety manual
            // 1. Update Winning Credits
            await env.DB.prepare(`
                UPDATE users SET winning_credits = winning_credits + ? WHERE id = ?
            `).bind(w.amount, w.userId).run();

            // 2. Insert Transaction Record
            await env.DB.prepare(`
                INSERT INTO transactions (id, user_id, type, amount, contest_id, created_at, status)
                VALUES (?, ?, 'winnings', ?, ?, ?, 'success')
            `).bind(txnId, w.userId, w.amount, contestId, Date.now()).run();

        } catch (e) {
            console.error(`Failed to payout user ${w.userId} for contest ${contestId}:`, e);
            // Log failure to a hypothetical 'payout_failures' table or retry logic
        }
    }
}
