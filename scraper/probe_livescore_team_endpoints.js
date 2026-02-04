
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const HOST = 'livescore6.p.rapidapi.com';
const TEAM_ID = '86110'; // England (from previous step)

async function probe() {
    const endpoints = [
        // TEAM ENDPOINTS - Probe these
        `/teams/v2/get-squad?Tid=${TEAM_ID}&Category=cricket`,
        `/teams/v2/list-players?Tid=${TEAM_ID}&Category=cricket`,
        `/teams/v2/get-team?Tid=${TEAM_ID}&Category=cricket`,

        // SEARCH ENDPOINT (User mentioned this works)
        `/suggest/v2/search?Val=england&Category=cricket`,

        // GENERIC
        `/teams/details?team_id=${TEAM_ID}`,
        `/teams/v2/get-info?Tid=${TEAM_ID}`
    ];

    for (const ep of endpoints) {
        const url = `https://${HOST}${ep}`;
        console.log(`\nProbing: ${url}`);
        try {
            const r = await fetch(url, { headers: { 'x-rapidapi-key': RAPID_API_KEY, 'x-rapidapi-host': HOST } });
            console.log(`Status: ${r.status}`);
            if (r.ok) {
                const txt = await r.text();
                if (txt.length > 500) console.log(`Response: ${txt.substring(0, 500)}...`);
                else console.log(`Response: ${txt}`);
            }
        } catch (e) { console.log("Err:", e.message); }
    }
}

probe();
