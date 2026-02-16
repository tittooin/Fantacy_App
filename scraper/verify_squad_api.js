const workerUrl = 'https://fantasy-cricket-api.moremagical4.workers.dev';
// const workerUrl = 'http://127.0.0.1:8787'; // Local verify if needed

async function verifySquad() {
    // 1. Trigger Squad Sync (Manual - via existing flow if possible, or just read)
    // We can't easily trigger sync without the cron or live match.
    // But we can check an existing match if available.

    // Let's try to get squads for a known match ID
    const matchId = '103505'; // Example ID

    console.log(`Fetching Squads for ${matchId}...`);
    try {
        const resp = await fetch(`${workerUrl}/api/squads?matchId=${matchId}`);
        const data = await resp.json();

        if (!data.success) {
            console.log("Failed:", data);
            return;
        }

        console.log("✅ Success!");
        console.log(`Source: ${data.source}`);

        const teamA = data.teamA || [];
        console.log(`Team A Count: ${teamA.length}`);

        if (teamA.length > 0) {
            console.log("Sample Player:", JSON.stringify(teamA[0], null, 2));

            // Verify Sorting
            console.log("\n--- Sorting Check ---");
            const roles = teamA.map(p => p.role);
            console.log("Roles Order:", roles.slice(0, 10).join(', '));

            // Check for Deterministic Credits/Rating
            console.log("Credits:", teamA.map(p => p.credits).slice(0, 5).join(', '));
            console.log("Ratings:", teamA.map(p => p.fantasy_rating).slice(0, 5).join(', '));
        }

    } catch (e) {
        console.error(e);
    }
}

verifySquad();
