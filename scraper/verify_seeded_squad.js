const workerUrl = 'https://fantasy-cricket-api.moremagical4.workers.dev';

async function verifySquad() {
    const matchId = '999999'; // Test ID

    console.log(`Fetching Squads for ${matchId}...`);
    try {
        const resp = await fetch(`${workerUrl}/api/squads?matchId=${matchId}`);
        const data = await resp.json();

        if (!data.success) {
            console.log("Failed:", data);
            return;
        }

        console.log("✅ Success!");
        console.log(`Source: ${data.source}`); // Should be D1_RUNTIME_MERGE (or MEM_CACHE)

        const teamA = data.teamA || [];
        console.log(`Team A Count: ${teamA.length}`);

        // Expected Order: WK (p2) -> BAT (p3) -> AR (p4) -> BOWL (p1)
        console.log("\n--- Sorting Check (Expect: WK, BAT, AR, BOWL) ---");
        const roles = teamA.map(p => p.role);
        console.log(`Actual Roles: ${roles.join(', ')}`);

        console.log("\n--- Deterministic Hash Check ---");
        teamA.forEach(p => {
            console.log(`${p.name} (${p.role}): Credits=${p.credits}, Rating=${p.fantasy_rating}`);
        });

    } catch (e) {
        console.error(e);
    }
}

verifySquad();
