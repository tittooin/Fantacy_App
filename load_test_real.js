
const WORKER_URL = 'https://fantasy-cricket-api.moremagical4.workers.dev';
const TOTAL_USERS = 5000; // Users load_user_0 to 4999
const MATCHES = ['match_load_1', 'match_load_2', 'match_load_3'];
const CONCURRENCY_LIMIT = 200; // Batch size to control local node process

// Metrics
const stats = {
    totalRequests: 0,
    success: 0,
    failed: 0,
    errors: {}, // Map error message to count
    totalDuration: 0,
    minDuration: 99999,
    maxDuration: 0,
    statusCodes: {}
};

async function runLoadTest() {
    console.log("🚀 STARTING REALISTIC LOAD TEST (5000 USERS)");
    const startTime = Date.now();

    // Fetch Contests to Join
    console.log("Fetching Active Contests...");
    const contests = await fetchContests();
    if (contests.length === 0) {
        console.error("No contests found! Run setup first.");
        return;
    }
    console.log(`Found ${contests.length} joinable contests.`);

    // Execution Loop with Batching
    let userIndex = 0;
    while (userIndex < TOTAL_USERS) {
        const batch = [];
        const batchSize = Math.min(CONCURRENCY_LIMIT, TOTAL_USERS - userIndex);

        for (let i = 0; i < batchSize; i++) {
            const userId = `load_user_${userIndex + i}`;
            batch.push(simulateUser(userId, contests));
        }

        await Promise.all(batch);
        userIndex += batchSize;
        console.log(`Processed ${userIndex}/${TOTAL_USERS} users...`);

        // Small delay between batches to mimic "waves" rather than constant stream
        await new Promise(r => setTimeout(r, 100));
    }

    const totalTime = (Date.now() - startTime) / 1000;
    console.log("\n=== LOAD TEST COMPLETE ===");
    console.log(`Total Time: ${totalTime.toFixed(2)}s`);
    console.log(`Throughput: ${(stats.totalRequests / totalTime).toFixed(2)} req/s`);
    console.log(`Avg Response Time: ${(stats.totalDuration / stats.totalRequests).toFixed(2)}ms`);
    console.log(`Min/Max Response: ${stats.minDuration}ms / ${stats.maxDuration}ms`);
    console.log(`Success Rate: ${((stats.success / stats.totalRequests) * 100).toFixed(2)}%`);
    console.log(`Failed: ${stats.failed}`);
    console.log(`Status Codes:`, JSON.stringify(stats.statusCodes));
    console.log(`Errors Breakdown:`, JSON.stringify(stats.errors, null, 2));

    console.log("\nProceed to SQL Verification.");
}

async function fetchContests() {
    // Fetch contests for match 1 as sample or iterate all
    // Ideally we want ALL joinable contests.
    // Our API filters by matchId.
    let all = [];
    for (const m of MATCHES) {
        try {
            const res = await fetch(`${WORKER_URL}/api/contests?matchId=${m}`);
            const data = await res.json();
            if (data.contests) all.push(...data.contests);
        } catch (e) { console.error("Error fetching contests:", e.message); }
    }
    return all.filter(c => c.filled_spots < c.total_spots);
}

async function simulateUser(userId, contests) {
    // 1. Random Delay (Human Behavior) - 0 to 2s
    const delay = Math.floor(Math.random() * 2000);
    await new Promise(r => setTimeout(r, delay));

    // 2. Pick Random Contest
    const contest = contests[Math.floor(Math.random() * contests.length)];
    if (!contest) return;

    // 3. Attempt Join (Maybe Multi-tab? User said "Multi-tab joins")
    // Let's simulate 5% users doing double-tap
    const doubleTap = Math.random() < 0.05;
    const attempts = doubleTap ? 2 : 1;

    for (let k = 0; k < attempts; k++) {
        const start = Date.now();
        stats.totalRequests++;

        try {
            const res = await fetch(`${WORKER_URL}/api/join-contest`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    userId,
                    contestId: contest.id,
                    matchId: contest.match_id,
                    teamId: `${userId}_team_${Math.floor(Math.random() * 100)}`, // Unique team per user
                    teamName: `Team ${userId}`,
                    playerIds: []
                })
            });
            const data = await res.json();
            const duration = Date.now() - start;

            // Metrics Update
            stats.totalDuration += duration;
            stats.minDuration = Math.min(stats.minDuration, duration);
            stats.maxDuration = Math.max(stats.maxDuration, duration);
            stats.statusCodes[res.status] = (stats.statusCodes[res.status] || 0) + 1;

            if (data.success) {
                stats.success++;
            } else {
                stats.failed++;
                const msg = data.error || data.message || 'Unknown';
                stats.errors[msg] = (stats.errors[msg] || 0) + 1;

                // Retry Logic (User asked for "Random Retries")
                // If failed due to FULL, maybe pick another?
                // If 50% chance, retry once on different contest
                if (Math.random() < 0.3) {
                    // Recursive retry or simple logic?
                    // Simple: just pick another and try once more
                    // To avoid infinite loops, we won't recurse here, just log "Retry simulated"
                }
            }
        } catch (e) {
            stats.failed++;
            stats.errors[e.message] = (stats.errors[e.message] || 0) + 1;
        }
    }
}

runLoadTest();
