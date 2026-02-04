
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const MATCH_ID = '145451'; // From screenshot

async function debugSquadSync() {
    const primaryHost = 'unofficial-cricbuzz.p.rapidapi.com';
    const backupHost = 'free-cricbuzz-cricket-api.p.rapidapi.com';

    console.log(`🔍 Debugging Squad Sync for Match ${MATCH_ID}`);

    // 1. Try Primary Host (Scorecard)
    try {
        console.log(`\n--- PRIMARY HOST PROBE ---`);
        const url = `https://${primaryHost}/matches/get-scorecard?matchId=${MATCH_ID}`;
        console.log(`fetching: ${url}`);
        const resp = await fetch(url, { headers: { 'x-rapidapi-key': RAPID_API_KEY, 'x-rapidapi-host': primaryHost } });
        console.log(`Status: ${resp.status}`);
        if (resp.ok) {
            const data = await resp.json();
            console.log("Primary Keys:", Object.keys(data));
        } else {
            console.log("Primary Failed (likely 429)");
        }
    } catch (e) { console.error("Primary Error:", e.message); }

    // 2. Try Backup Host (Scorecard)
    try {
        console.log(`\n--- BACKUP HOST PROBE (Scorecard) ---`);
        const url = `https://${backupHost}/matches/get-scorecard?matchId=${MATCH_ID}`;
        console.log(`fetching: ${url}`);
        const resp = await fetch(url, { headers: { 'x-rapidapi-key': RAPID_API_KEY, 'x-rapidapi-host': backupHost } });
        console.log(`Status: ${resp.status}`);
        if (resp.ok) {
            const data = await resp.json();
            // Log raw structure to see if it matches what we expect
            console.log("Backup Data Preview:", JSON.stringify(data, null, 2).substring(0, 1000));
        }
    } catch (e) { console.error("Backup Error:", e.message); }

    // 3. Try Backup Host (Get Info -> Roster Fallback) - CORRECTED ENDPOINTS
    try {
        console.log(`\n--- BACKUP HOST PROBE (Get Info) ---`);
        // Note: Free API uses different endpoints
        const url = `https://${backupHost}/cricket-match-info?matchId=${MATCH_ID}`;
        console.log(`fetching: ${url}`);
        const resp = await fetch(url, { headers: { 'x-rapidapi-key': RAPID_API_KEY, 'x-rapidapi-host': backupHost } });
        console.log(`Status: ${resp.status}`);

        if (resp.ok) {
            const data = await resp.json();
            console.log("Info Data:", JSON.stringify(data, null, 2).substring(0, 2000));

            // Expected Structure: data.response.matchInfo OR data.matchInfo
            const info = data.response?.matchInfo || data.matchInfo;

            // Try extracting team IDs from possibly different fields
            const t1 = info?.team1?.teamId || info?.team1?.id;
            const t2 = info?.team2?.teamId || info?.team2?.id;
            console.log(`Extracted Team IDs: T1=${t1}, T2=${t2}`);

            if (t1) await probeTeamRoster(t1, backupHost);
        }
    } catch (e) { console.log("Backup Info Error:", e.message); }
}

async function probeTeamRoster(teamId, host) {
    console.log(`\n--- Probing Team Roster for ${teamId} on ${host} ---`);
    // Free API Endpoint: /cricket-team-squad (Found in previous research/docs)
    const url = `https://${host}/cricket-team-squad?teamId=${teamId}`;
    try {
        const resp = await fetch(url, { headers: { 'x-rapidapi-key': RAPID_API_KEY, 'x-rapidapi-host': host } });
        if (resp.ok) {
            const data = await resp.json();
            console.log("Roster Data Preview:", JSON.stringify(data, null, 2).substring(0, 1000));
            // Check if players are returned
            const players = data.response?.players || data.players;
            console.log(`Players Found: ${players ? players.length : 0}`);
        } else {
            console.log(`Roster Fetch Failed: ${resp.status}`);
        }
    } catch (e) { console.log("Roster Error:", e.message); }
}

debugSquadSync();
