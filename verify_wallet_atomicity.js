// Native Fetch used.

const WORKER_URL = 'https://fantasy-cricket-api.moremagical4.workers.dev';
const TEST_MATCH_ID = '999999';

async function runTest() {
    console.log("💰 STARTING WALLET ATOMICITY VERIFICATION (PHASE 9.3)");

    // --- TEST 1: LOW BALANCE PROTECTION ---
    console.log(`\n=== TEST 1: LOW BALANCE (25 Credits, Fee 10) ===`);
    // User: atomic_poor (25)
    // Contest: Unlimited spots (or large enough), Fee 10.
    const contestId1 = `low_bal_${Date.now()}`;
    await createContest(contestId1, 10, 10); // 10 Spots, Fee 10

    console.log(`Simulating 5 Parallel Joins...`);
    const promises = [];
    for (let i = 1; i <= 5; i++) {
        promises.push(joinContest(contestId1, 'atomic_poor', TEST_MATCH_ID));
    }
    const results = await Promise.all(promises);
    const successCount = results.filter(r => r.success).length;

    console.log(`Results: ${successCount} Success, ${5 - successCount} Failed`);
    if (successCount === 2) console.log("✅ PASS: Strictly 2 joins allowed.");
    else console.error(`❌ FAIL: Expected 2, got ${successCount}`);

    // --- TEST 2: ROLLBACK ON FAILURE ---
    console.log(`\n=== TEST 2: ROLLBACK ON FAILURE (1 Spot, Fee 10) ===`);
    // User: atomic_rollback (100)
    // Contest: 1 Spot Only. Fee 10.
    // We send 3 joins.
    // 1 Success. 2 Failure (Contest Full).
    // IF Atomicity works: Wallet should be deducted ONCE (100 - 10 = 90).
    // IF Failed: Wallet might be 80 or 70.
    const contestId2 = `rollback_${Date.now()}`;
    await createContest(contestId2, 1, 10); // 1 Spot, Fee 10

    console.log(`Simulating 3 Parallel Joins...`);
    const promises2 = [];
    for (let i = 1; i <= 3; i++) {
        promises2.push(joinContest(contestId2, 'atomic_rollback', TEST_MATCH_ID));
    }
    await Promise.all(promises2);

    console.log("Joins complete. Checking balance...");

    // Check via API? Or reliance on SQL later. 
    // We'll rely on SQL dump in the next step for definitive proof.
    // But let's verify login/profile balance if possible?
    // We don't have a direct profile fetch in this script, will use SQL.
    console.log("✅ Test Execution Complete. Proceed to SQL Proof.");
}

async function createContest(id, spots, fee) {
    await fetch(`${WORKER_URL}/api/admin/contests/create`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            id, matchId: TEST_MATCH_ID, entryFee: fee, totalSpots: spots, prizePool: fee * spots,
            category: 'AtomicityTest', isGuaranteed: true, isFlexible: false, winningBreakdown: []
        })
    });
}

async function joinContest(contestId, userId, matchId) {
    const res = await fetch(`${WORKER_URL}/api/join-contest`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            userId, contestId, matchId,
            teamId: `${userId}_${Date.now()}_${Math.random()}`,
            teamName: 'Atomic Team',
            playerIds: []
        })
    });
    return await res.json();
}

runTest();
