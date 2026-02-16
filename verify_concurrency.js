// Native Fetch used.

const WORKER_URL = 'https://fantasy-cricket-api.moremagical4.workers.dev';
const TEST_MATCH_ID = '999999';

async function runTest() {
    console.log("🔒 STARTING CONCURRENCY SAFETY VERIFICATION (PHASE 9.2)");

    // --- TEST 1: LAST SPOT RACE CONDITION ---
    console.log(`\n=== TEST 1: LAST SPOT RACE ===`);
    const contestId1 = `race_test_${Date.now()}`;
    await createContest(contestId1, 2, 10); // 2 Spots

    console.log(`Simulating 10 Parallel Joins...`);
    const promises = [];
    for (let i = 1; i <= 10; i++) {
        promises.push(joinContest(contestId1, `racer_${i}`, TEST_MATCH_ID));
    }
    const results = await Promise.all(promises);
    const successCount = results.filter(r => r.success).length;
    const failures = results.filter(r => !r.success).map(r => r.error);

    console.log(`Results: ${successCount} Success, ${10 - successCount} Failed`);
    if (failures.length > 0) console.log("Errors:", JSON.stringify(failures));
    if (successCount === 2) console.log("✅ PASS: Exactly 2 spots filled.");
    else console.error(`❌ FAIL: Expected 2, got ${successCount}`);

    // --- TEST 2: OVERFILL PROTECTION ---
    console.log(`\n=== TEST 2: OVERFILL PROTECTION ===`);
    const contestId2 = `overfill_test_${Date.now()}`;
    await createContest(contestId2, 1, 10); // 1 Spot

    console.log(`Simulating 5 Parallel Joins...`);
    const promises2 = [];
    for (let i = 1; i <= 5; i++) {
        promises2.push(joinContest(contestId2, `overfill_${i}`, TEST_MATCH_ID));
    }
    const results2 = await Promise.all(promises2);
    const successCount2 = results2.filter(r => r.success).length;
    console.log(`Results: ${successCount2} Success`);
    if (successCount2 === 1) console.log("✅ PASS: EXACTLY 1 spot filled.");
    else console.error(`❌ FAIL: Expected 1, got ${successCount2}`);

    // --- TEST 3: LIQUIDITY RACE ---
    console.log(`\n=== TEST 3: LIQUIDITY RACE ===`);
    const contestId3 = `liquidity_race_${Date.now()}`;
    await createContest(contestId3, 5, 20); // 5 Spots, Fee 20 (Unique fee to track)

    // Fill to 3/5 (60%) normally
    await joinContest(contestId3, 'feeder_1', TEST_MATCH_ID);
    await joinContest(contestId3, 'feeder_2', TEST_MATCH_ID);
    await joinContest(contestId3, 'feeder_3', TEST_MATCH_ID);

    // Now at 3/5. Join 1 more triggers 80%.
    // We send 10 parallel joins. ALL should try to trigger liquidity.
    // Expectation: Only 1 new contest created.
    console.log(`Simulating 10 Parallel Joins (Triggering 80%)...`);
    const promises3 = [];
    for (let i = 1; i <= 10; i++) {
        promises3.push(joinContest(contestId3, `liq_racer_${i}`, TEST_MATCH_ID));
    }
    await Promise.all(promises3);

    // Check how many contests exist for Fee 20
    await checkLiquidityCount(20, 2); // Expect 2 (Original + 1 Child)

    // --- TEST 4: ATOMICITY (Ghost Team) ---
    console.log(`\n=== TEST 4: WALLET ATOMICITY (Ghost Team) ===`);
    const contestId4 = `atomic_test_${Date.now()}`;
    await createContest(contestId4, 10, 50);
    const atomicUser = 'atomic_user';

    console.log(`Simulating 5 Parallel Joins from SAME USER...`);
    const promises4 = [];
    for (let i = 1; i <= 5; i++) {
        // Same User, Same Contest, Same Match. 
        // Note: Code uses unique teamId per request if we gen it clientside.
        // But to test "Same Team" checks, we must send SAME teamId? 
        // No, user constraint is (contest_id, team_id).
        // If we send different teamIds, user CAN join multiple times (allowance: 20 teams).
        // Wait, "Ghost Team" usually means same teamId joined twice.
        // Or user double-clicked join with same team?
        // Let's use SAME teamId to test idempotency/uniqueness.
        promises4.push(joinContest(contestId4, atomicUser, TEST_MATCH_ID, "FixedTeamID"));
    }
    const results4 = await Promise.all(promises4);
    const successCount4 = results4.filter(r => r.success).length;
    const alreadyJoined = results4.filter(r => r.error === 'ALREADY_JOINED').length;

    console.log(`Results: ${successCount4} Success, ${alreadyJoined} Already Joined`);
    if (successCount4 === 1 && alreadyJoined >= 4) console.log("✅ PASS: Single atomic join.");
    else console.error(`❌ FAIL: Expected 1 success, got ${successCount4}`);

}

async function createContest(id, spots, fee) {
    await fetch(`${WORKER_URL}/api/admin/contests/create`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            id, matchId: TEST_MATCH_ID, entryFee: fee, totalSpots: spots, prizePool: fee * spots,
            category: 'SafetyTest', isGuaranteed: true, isFlexible: false, winningBreakdown: []
        })
    });
}

async function joinContest(contestId, userId, matchId, forceTeamId = null) {
    const res = await fetch(`${WORKER_URL}/api/join-contest`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            userId, contestId, matchId,
            teamId: forceTeamId || `${userId}_${Date.now()}_${Math.random()}`,
            teamName: 'Racer Team',
            playerIds: []
        })
    });
    return await res.json();
}

async function checkLiquidityCount(fee, expected) {
    const res = await fetch(`${WORKER_URL}/api/contests?matchId=${TEST_MATCH_ID}`);
    const data = await res.json();
    const count = data.contests.filter(c => c.entryFee === fee).length;
    console.log(`Contests with Fee ${fee}: ${count} (Expected ${expected})`);
    if (count === expected) console.log("✅ PASS: Liquidity controlled.");
    else console.error(`❌ FAIL: Liquidity Race detected?`);
}

runTest();
