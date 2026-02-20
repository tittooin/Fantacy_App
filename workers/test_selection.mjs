
// Native fetch is available in Node 18+

const WORKER_URL = "http://127.0.0.1:8787"; // Default local wrangler dev port
// const MATCH_ID = 139329; // Sri Lanka vs Zimbabwe (Live)
const MATCH_ID = 139307; // India vs Netherlands (Live) - choosing this one

async function runTests() {
    console.log("Starting 11 Player Selection Test (State Lock Phase)...");

    // Helper to fetch squad to get valid player IDs
    // Updated URL to matching index.js route
    async function getSquad() {
        console.log(`Fetching squad from: ${WORKER_URL}/api/squads?matchId=${MATCH_ID}`);
        const res = await fetch(`${WORKER_URL}/api/squads?matchId=${MATCH_ID}`);
        if (!res.ok) {
            console.error(`Get Squad Failed: ${res.status} ${res.statusText}`);
            const txt = await res.text();
            console.error("Body:", txt);
            return null;
        }
        const data = await res.json();
        return data;
    }

    // Helper to join contest
    // Updated URL to matching index.js route
    async function joinContest(caseName, payload) {
        console.log(`\n--- ${caseName} ---`);
        console.log("Request Payload:", JSON.stringify(payload, null, 2));
        try {
            const res = await fetch(`${WORKER_URL}/api/join-contest`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
            const data = await res.json();
            console.log("Response:", JSON.stringify(data, null, 2));
            return data;
        } catch (e) {
            console.error("Error:", e.message);
        }
    }

    try {
        console.log(`Fetching squad for Match ID: ${MATCH_ID}...`);
        const squadData = await getSquad();

        if (!squadData) {
            console.error("Failed to fetch valid squad data. Aborting.");
            return;
        }

        let homePlayers = [];
        let awayPlayers = [];

        if (squadData.teamA && squadData.teamB) {
            console.log("Detected structure: { teamA, teamB }");
            homePlayers = squadData.teamA;
            awayPlayers = squadData.teamB;
        } else if (squadData.data && squadData.data.home_team) {
            console.log("Detected structure: { data: { home_team... } }");
            homePlayers = squadData.data.home_team.players || squadData.data.home_team;
            awayPlayers = squadData.data.away_team.players || squadData.data.away_team;
        } else {
            console.error("Unknown Squad Structure Keys:", Object.keys(squadData));
            console.error("Squad Data:", JSON.stringify(squadData, null, 2));
            return;
        }

        const allPlayers = [...homePlayers, ...awayPlayers];
        console.log(`Squad fetched. Home: ${homePlayers.length}, Away: ${awayPlayers.length}`);

        if (allPlayers.length < 15) {
            console.error("Not enough players to run tests.");
            return;
        }

        // Prepare Player IDs
        // Case 1: 11 unique valid players (Mixed teams)
        const valid11 = allPlayers.slice(0, 11).map(p => p.id || p.player_id);

        // Case 2: 10 players
        const valid10 = allPlayers.slice(0, 10).map(p => p.id || p.player_id);

        // Case 3: 12 players
        const valid12 = allPlayers.slice(0, 12).map(p => p.id || p.player_id);

        // Case 4: 11 players same team
        // Try home team first
        let sameTeam11 = homePlayers.slice(0, 11).map(p => p.id || p.player_id);
        if (sameTeam11.length < 11) {
            // Fallback to all from one list if possible, otherwise mix but this test might be weak if not enough players in one team
            sameTeam11 = homePlayers.slice(0, homePlayers.length).map(p => p.id || p.player_id);
            // This might not be 11, but we try our best.
        }

        // Case 5: 10 valid + 1 invalid
        const invalid11 = [...valid10, 99999999];

        const basePayload = {
            userId: "test_user_001",
            contestId: "test_contest_001", // Dummy - Might fail if DB check exists (it does).
            // contestId needs to be valid. We might need to fetch contests first?
            matchId: MATCH_ID,
            teamName: "Test Team A",
            teamId: "team_1" // Logic might require this
        };

        // Need a valid Contest ID?
        // The handleJoinContest checks keys first, then DB.
        // "Rule 1: Contest existence check" -> It will return CONTEST_NOT_FOUND or something if contestId is invalid.
        // This is FINE for validation testing (empty/oversized team check happens BEFORE contest check in index.js?)

        // Let's check index.js order:
        // 1. Missing fields check
        // 2. TEAM GUARD checks (Empty, Too Many, Duplicate) <<< THIS IS WHAT WE WANT TO TEST
        // 3. DB Lookups (User, Contest, Count)

        // So if we pass invalid contestId, we should still seeing validation errors for Team Guard tests.
        // For Valid Team test, we might get CONTEST_NOT_FOUND, which confirms the guard passed!

        // EXECUTE
        await joinContest("CASE 1: 11 Unique Valid Players (Expect: Success or Next Stage Error)", { ...basePayload, playerIds: valid11 });
        await joinContest("CASE 2: 10 Players (Expect: TOO_MANY_PLAYERS or similar invalid)", { ...basePayload, playerIds: valid10 });
        // logic says: if (pids.length > 11) error 'TOO_MANY_PLAYERS'. 
        // Wait, does it check MINIMUM? 
        // index.js: if (pids.length === 0) error 'EMPTY_TEAM'. 
        // It does NOT check for < 11. So 10 players might PASS the guard and hit DB checks. 
        // If logic doesn't enforce 11 specifically, then 10 is "valid" for the guard. 
        // I should check if there is a minimum check.

        await joinContest("CASE 3: 12 Players (Expect: TOO_MANY_PLAYERS)", { ...basePayload, playerIds: valid12 });
        await joinContest("CASE 4: 11 Players Same Team (Expect: Success or Next Stage Error)", { ...basePayload, playerIds: sameTeam11 });
        await joinContest("CASE 5: Random Invalid Player ID (Expect: Success or Next Stage Error - Guard doesn't check existence)", { ...basePayload, playerIds: invalid11 });
        // Guard only checks uniqueness and size. Validity of ID is not checked in Guard.

    } catch (err) {
        console.error("Test Execution Failed:", err);
    }
}

runTests();
