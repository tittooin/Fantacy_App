// Native Fetch used.

const WORKER_URL = 'https://fantasy-cricket-api.moremagical4.workers.dev';
// We use a specific matchId for testing to avoid messing up real matches
const TEST_MATCH_ID = '999999';
const TEST_USER_ID = 'test_safety_user';

async function runTest() {
    console.log("🔒 STARTING GAMEPLAY SAFETY VERIFICATION");

    // 1. Setup: Ensure we have a clean slate (optional, but good for repeatable tests)
    // We can't easily wipe remote DB via API, so we rely on unique IDs or assuming fresh state if possible.
    // Ideally we'd use a new match ID each run, but let's stick to 999999.

    // 2. Create a specific test contest via Admin API (to control spots)
    // We want a small contest, e.g., 5 spots, so 80% is 4 joins.
    const contestId = `lock_test_${Date.now()}`;
    console.log(`\n--- Step 1: Creating Test Contest [${contestId}] (5 Spots) ---`);

    const createResp = await fetch(`${WORKER_URL}/api/admin/contests/create`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            id: contestId,
            matchId: TEST_MATCH_ID,
            entryFee: 10,
            totalSpots: 5,
            prizePool: 40,
            category: 'SafetyTest',
            isGuaranteed: true,
            isFlexible: false,
            winningBreakdown: []
        })
    });
    console.log("Create Status:", createResp.status);

    // 3. Verify Visibility - Should see 1 contest
    console.log(`\n--- Step 2: Verify Initial Visibility ---`);
    await checkVisibility(TEST_MATCH_ID, 10, 1);

    // 4. Fill to 80% (4 users)
    console.log(`\n--- Step 3: Fill to 80% (Trigger Liquidity) ---`);
    for (let i = 1; i <= 4; i++) {
        await joinContest(contestId, `user_${i}`, TEST_MATCH_ID);
        // Small delay to allow async liquidity trigger
        await new Promise(r => setTimeout(r, 500));
    }

    // 5. Check Liquidity - Should see TWO contests now (Old one + New one)?
    // WAIT! Rule says "Har entry fee ka sirf 1 joinable contest visible".
    // If old is 80% (4/5), it is still joinable.
    // If liquidity triggered, a NEW empty one exists.
    // The filter logic says: "If selected matches strict criteria...".
    // Actually, `handleGetContests` logic: "One Active Contest Per Fee".
    // "If selected is full... replace... If NOT full, keep it".
    // So if old is 4/5 (not full), we should STILL see the old one. We won't see the new one until old is full.
    // Let's verify THAT specific behavior.
    console.log(`\n--- Step 4: Verify Visibility at 80% ---`);
    await checkVisibility(TEST_MATCH_ID, 10, 1);

    // 6. Fill to 100% (5th user)
    console.log(`\n--- Step 5: Fill to 100% (Lock Contest) ---`);
    await joinContest(contestId, `user_5`, TEST_MATCH_ID);

    // 7. Verify Visibility - Should NOW see the NEW contest (Empty)
    console.log(`\n--- Step 6: Verify Visibility after Full ---`);
    await checkVisibility(TEST_MATCH_ID, 10, 1); // Should still return 1 contest, but it must be the NEW one (filled=0)

    // 8. Try to Join Full Contest (Negative Case)
    console.log(`\n--- Step 7: Negative Case - Join Full Contest ---`);
    const fullResp = await joinContest(contestId, 'user_6', TEST_MATCH_ID);
    if (fullResp.error === 'CONTEST_FULL') console.log("✅ SUCCESS: Rejected Full Contest Join");
    else console.error("❌ FAILURE: Accepted Full Contest Join or wrong Error", fullResp);

    // 9. Test Max 20 Teams Limit
    console.log(`\n--- Step 8: Test Max 20 Teams Limit (Per Match) ---`);
    // We intentionally ignore contestId and just hit the match logic
    // We need a NEW user for this to be clean.
    const fatigueUser = `fatigue_tester`;
    // We need a contest that isn't full. We can use the liquidity-spawned one.
    // Fetch it first.
    const contests = await fetchContests(TEST_MATCH_ID);
    const targetContest = contests.find(c => c.entryFee === 10 && c.filledSpots < c.totalSpots);

    if (targetContest) {
        console.log(`Targeting Liquidity Contest: ${targetContest.id}`);
        // Join 20 times
        let successCount = 0;
        for (let i = 1; i <= 20; i++) {
            const res = await joinContest(targetContest.id, fatigueUser, TEST_MATCH_ID, `Team ${i}`);
            if (res.success) successCount++;
        }
        console.log(`Joined ${successCount}/20 times.`);

        // Try 21st time
        console.log("Attempting 21st Join...");
        const res21 = await joinContest(targetContest.id, fatigueUser, TEST_MATCH_ID, "Team 21");
        if (res21.error === 'LIMIT_EXCEEDED_20_TEAMS') console.log("✅ SUCCESS: 21st Team Rejected");
        else console.error("❌ FAILURE: 21st Team Allowed or wrong Error", res21);

    } else {
        console.error("❌ Could not find open contest for limit test");
    }

}

async function joinContest(contestId, userId, matchId, teamName = "Team A") {
    const res = await fetch(`${WORKER_URL}/api/join-contest`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            userId,
            contestId,
            matchId,
            teamId: `${userId}_${Date.now()}_${Math.random()}`, // Unique team ID
            teamName,
            playerIds: []
        })
    });
    const data = await res.json();
    return data;
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
    if (feeContests.length !== expectedCount) {
        console.error(`❌ Visibility Fail: Expected ${expectedCount}, Got ${feeContests.length}`);
    } else {
        const c = feeContests[0];
        console.log(`✅ Visibility OK. Active: ${c.id} (Filled: ${c.filledSpots}/${c.totalSpots})`);
    }
}

runTest();
