/**
 * Payout Engine
 * Automates Winnings Distribution when a Match is Completed.
 */

export async function processPayoutsForMatch(env, matchId) {
    console.log(`💰 Starting Payout Cycle for Match: ${matchId}`);

    try {
        // 1. Verify Match Status (Double Check)
        // We only process if Status is 'Completed'
        const match = await env.DB.prepare("SELECT status FROM matches WHERE id = ?").bind(matchId).first();
        if (!match || match.status !== 'Completed') {
            console.log("Match not completed yet. Skipping payouts.");
            return;
        }

        // 2. Get Contests for this Match
        // We fetch from D1 contests map (assuming it's synced) or query Firestore for all contests of this match.
        // For Quota Safety, let's try D1 first if we synced them. 
        // If not, we query Firestore (Costly but necessary for Payouts).
        // Optimization: Use D1 'contests' table if available.

        // Let's assume we use Firestore for the "Master List" of contests to be safe about money.
        const contests = await queryFirestore(env, 'contests', [
            { fieldPaths: ['matchId'], op: 'EQUAL', value: matchId },
            // Filter only active/live contests? 
            // Or un-distributed ones? Add status check if possible, or filter in code.
        ]);

        console.log(`Found ${contests.length} contests for match.`);

        for (const contest of contests) {
            // Check if already distributed?
            if (contest.fields.status?.stringValue === 'Distributed') {
                console.log(`Skipping ${contest.id} (Already Distributed)`);
                continue;
            }
            if (contest.fields.status?.stringValue === 'Cancelled') {
                continue;
            }

            await distributePrizes(env, contest);
        }

    } catch (e) {
        console.error(`❌ Payout Error for ${matchId}:`, e);
    }
}

async function distributePrizes(env, rawContest) {
    const contestId = rawContest.id;
    const breakdown = parseWinningBreakdown(rawContest.fields.winningBreakdown);

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

    const leaderboard = JSON.parse(lbRow.data); // [{ userId, rank, points, ... }]
    const winners = [];

    // 2. Determine Winners
    for (const entry of leaderboard) {
        const rank = entry.rank;
        const prize = getPrizeForRank(rank, breakdown);

        if (prize > 0) {
            winners.push({
                userId: entry.userId,
                amount: prize,
                rank: rank
            });
        }
    }

    if (winners.length === 0) {
        console.log("No winners found.");
        return;
    }

    // 3. Execute Batch Payouts (Firestore)
    console.log(`💸 Distributing to ${winners.length} winners...`);
    await processBatchPayments(env, winners, contestId);

    // 4. Mark Contest as Distributed
    await updateFirestoreDoc(env, `contests/${contestId}`, { status: 'Distributed' });

    // 5. Audit in D1 (Optional)
    await env.DB.prepare("INSERT OR REPLACE INTO contest_payouts (contest_id, match_id, total_distributed, processed_at) VALUES (?, ?, ?, ?)")
        .bind(contestId, rawContest.fields.matchId.stringValue, winners.reduce((sum, w) => sum + w.amount, 0), Date.now())
        .run();

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
    if (!field || !field.arrayValue || !field.arrayValue.values) return [];
    return field.arrayValue.values.map(v => {
        // Each value is a Map
        const map = v.mapValue.fields;
        return {
            rankStart: parseInt(map.rankStart.integerValue),
            rankEnd: parseInt(map.rankEnd.integerValue),
            amount: parseFloat(map.amount.integerValue || map.amount.doubleValue)
        };
    });
}


// --- INFRASTRUCTURE HELPERS (Firestore) ---

async function processBatchPayments(env, winners, contestId) {
    const baseUrl = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents`;

    // Firestore Batch has limit of 500 writes.
    // If winners > 250 (since we do 2 writes per winner: Wallet + Txn), we need to chunk.
    const CHUNK_SIZE = 100;

    for (let i = 0; i < winners.length; i += CHUNK_SIZE) {
        const chunk = winners.slice(i, i + CHUNK_SIZE);
        await executeBatchChunk(env, chunk, contestId, baseUrl);
    }
}

async function executeBatchChunk(env, winners, contestId, baseUrl) {
    // We can't use `commit` easily with simple REST without constructing a complex Multipart body or strict JSON.
    // Alternatively, we run parallel fetches for simpler implementation in Worker stats constraints.
    // But massive parallel fetches might hit rate limits.
    // Let's use `commit` endpoint properly if possible, OR just loop await for safety (slow but reliable).
    // Given "quota" constraints, reads are the problem. Writes are usually higher quota (20k/day).
    // Loop valid.

    // Optimization: Use `firestore:commit` REST API which writes atomically.
    // Structure: { writes: [ { update: ... }, { transform: ... } ] }

    const writes = [];

    for (const w of winners) {
        const txnId = `win_${contestId}_${w.userId}`;

        // 1. Transaction Record
        writes.push({
            update: {
                name: `${baseUrl}/transactions/${txnId}`,
                fields: {
                    id: { stringValue: txnId },
                    userId: { stringValue: w.userId },
                    amount: { doubleValue: w.amount },
                    type: { stringValue: 'winnings' },
                    contestId: { stringValue: contestId },
                    rank: { integerValue: w.rank.toString() }, // Cast to string for integerValue? No, integerValue takes string of number.
                    status: { stringValue: 'success' },
                    createdAt: { stringValue: new Date().toISOString() }
                }
            }
        });

        // 2. Wallet Increment (Transform)
        writes.push({
            transform: {
                document: `${baseUrl}/users/${w.userId}`,
                fieldTransforms: [
                    {
                        fieldPath: "walletCoins",
                        increment: { doubleValue: w.amount }
                    }
                ]
            }
        });
    }

    const body = { writes };

    const res = await fetch(`${baseUrl}:commit?key=${env.FIREBASE_API_KEY}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body)
    });

    if (!res.ok) {
        console.error("Batch Write Failed:", await res.text());
    }
}

// ... Reusing Firestore helpers from other files or duplicated here for isolation ...
async function updateFirestoreDoc(env, path, fields) {
    const baseUrl = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/${path}?key=${env.FIREBASE_API_KEY}`;

    // Convert flat fields to Firestore format
    const fsFields = {};
    for (const [k, v] of Object.entries(fields)) {
        if (typeof v === 'string') fsFields[k] = { stringValue: v };
    }

    await fetch(baseUrl, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ fields: fsFields })
    });
}

async function queryFirestore(env, collection, filters) {
    const url = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents:runQuery?key=${env.FIREBASE_API_KEY}`;

    const where = {
        compositeFilter: {
            op: 'AND',
            filters: filters.map(f => ({
                fieldFilter: {
                    field: { fieldPath: f.fieldPaths[0] },
                    op: f.op,
                    value: { stringValue: f.value }
                }
            }))
        }
    };

    const body = {
        structuredQuery: {
            from: [{ collectionId: collection }],
            where: where
        }
    };

    try {
        const res = await fetch(url, {
            method: 'POST',
            body: JSON.stringify(body)
        });
        const data = await res.json();
        return (data || []).map(d => {
            if (!d.document) return null;
            return {
                id: d.document.name.split('/').pop(),
                fields: d.document.fields
            };
        }).filter(Boolean);
    } catch (e) {
        return [];
    }
}
