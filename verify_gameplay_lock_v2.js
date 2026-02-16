// Native Fetch used.

const WORKER_URL = 'https://fantasy-cricket-api.moremagical4.workers.dev';
const TEST_MATCH_ID = '999999';

async function runTest() {
    console.log("🔒 STARTING GAMEPLAY SAFETY VERIFICATION V2");

    // --- PHASE 1: LIQUIDITY & VISIBILITY (Small Contest) ---
    const smallContestId = `liquidity_test_${Date.now()}`;
    console.log(`\n--- Step 1: Create Small Contest [${smallContestId}] (5 Spots) ---`);
    await createContest(smallContestId, 5, 10); // Fee 10, Spots 5

    console.log(`\n--- Step 2: Fill Small Contest to 80% (4 Users) ---`);
    for (let i = 1; i <= 4; i++) {
        // user_1 to user_4 are seeded
        await joinContest(smallContestId, `user_${i}`, TEST_MATCH_ID);
        await new Promise(r => setTimeout(r, 500));
    }

    console.log(`\n--- Step 3: Verify Liquidity (New Contest Created?) ---`);
    // We check via API visibility. 
    // Expectation: Old contest (4/5) is still visible? 
    // Or new one (0/5)?
    // Logic: "Active Contest" = Oldest non-full. 
    // 4/5 is non-full. So we should see Old one.
    // BUT a new one should EXIST in DB.
    await checkVisibility(TEST_MATCH_ID, 10, 1);

    console.log(`\n--- Step 4: Fill Small Contest to 100% (5th User) ---`);
    await joinContest(smallContestId, 'user_5', TEST_MATCH_ID);

    console.log(`\n--- Step 5: Verify Visibility After Full ---`);
    // Now Old is 5/5 (Full).
    // Visibility should switch to the NEW contest (spawned by liquidity).
    // The new contest has 0/5 spots.
    await checkVisibility(TEST_MATCH_ID, 10, 1);


    // --- PHASE 2: MAX 20 TEAMS LIMIT (Large Contest) ---
    const largeContestId = `limit_test_${Date.now()}`;
    console.log(`\n--- Step 6: Create Large Contest [${largeContestId}] (50 Spots) ---`);
    await createContest(largeContestId, 50, 11); // Fee 11 to differentiate

    console.log(`\n--- Step 7: Join 20 Times with 'fatigue_tester' ---`);
    let successCount = 0;
    for (let i = 1; i <= 20; i++) {
        const res = await joinContest(largeContestId, 'fatigue_tester', TEST_MATCH_ID, `Team ${i}`);
        if (res.success) successCount++;
        else console.log(`   Join ${i} Failed:`, res.error);
    }
    console.log(`Joined ${successCount}/20 times.`);

    console.log(`\n--- Step 8: Attempt 21st Join (Should Fail) ---`);
    const res21 = await joinContest(largeContestId, 'fatigue_tester', TEST_MATCH_ID, "Team 21");
    if (res21.error === 'LIMIT_EXCEEDED_20_TEAMS') {
        console.log("✅ SUCCESS: 21st Team Rejected (Limit Exceeded)");
    } else {
        console.error("❌ FAILURE: 21st Team Result:", res21);
    }

    // --- PHASE 3: NEGATIVE TESTS ---
    console.log(`\n--- Step 9: Negative - Join Full Contest ---`);
    // smallContestId is full (5/5). Try to join it explicitly.
    const fullRes = await joinContest(smallContestId, 'user_6', TEST_MATCH_ID);
    if (fullRes.error === 'CONTEST_FULL') {
        console.log("✅ SUCCESS: Rejected Full Contest Join");
    } else {
        console.error("❌ FAILURE: Full Contest Result:", fullRes);
    }

}

async function createContest(id, spots, fee) {
    const res = await fetch(`${WORKER_URL}/api/admin/contests/create`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            id,
            matchId: TEST_MATCH_ID,
            entryFee: fee,
            totalSpots: spots,
            prizePool: fee * spots, // simple math
            category: 'SafetyTest',
            isGuaranteed: true,
            isFlexible: false,
            winningBreakdown: []
        })
    });
    console.log(`Create [${id}] Status:`, res.status);
}

async function joinContest(contestId, userId, matchId, teamName = "Team A") {
    const res = await fetch(`${WORKER_URL}/api/join-contest`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            userId,
            contestId,
            matchId,
            teamId: `${userId}_${Date.now()}_${Math.random()}`,
            teamName,
            playerIds: []
        })
    });
    return await res.json();
}

async function fetchContests(matchId) {
    const res = await fetch(`${WORKER_URL}/api/contests?matchId=${matchId}`);
    const data = await res.json();
    return data.contests || [];
}

async function checkVisibility(matchId, fee, expectedCount) {
    const contests = await fetchContests(matchId);
    const feeContests = contests.filter(c => c.entryFee === fee);
    console.log(`Visible Contests for Fee ${fee}: ${feeContests.length}`);

    if (feeContests.length > 0) {
        const c = feeContests[0];
        console.log(`   Active: ${c.id} (Filled: ${c.filledSpots}/${c.totalSpots})`);
    } else {
        console.log(`   Active: NONE`);
    }

    if (feeContests.length !== expectedCount) {
        console.error(`❌ Visibility Fail: Expected ${expectedCount}, Got ${feeContests.length}`);
    } else {
        console.log(`✅ Visibility Count OK`);
    }
}

runTest();
