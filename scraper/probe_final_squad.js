
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'unofficial-cricbuzz.p.rapidapi.com';
const seriesId = '10102';
const squadId = '104426';

async function run() {
    console.log(`🔍 Final Probe for Squad ID ${squadId} (Series ${seriesId})...\n`);
    const endpoints = [
        `/series/get-squad?seriesId=${seriesId}&squadId=${squadId}`,
        `/squads/get-players?seriesId=${seriesId}&squadId=${squadId}`,
        `/teams/get-players?squadId=${squadId}`,
        `/match/get-squad?matchId=121422`, // Retry match-based
        `/series/get-players?squadId=${squadId}` // Retrying the 204 one
    ];

    for (const ep of endpoints) {
        const url = `https://${host}${ep}`;
        console.log(`Testing: ${url}`);
        try {
            const resp = await fetch(url, {
                headers: {
                    'x-rapidapi-key': RAPID_API_KEY,
                    'x-rapidapi-host': host,
                    'User-Agent': 'Mozilla/5.0'
                }
            });
            console.log(`Status: ${resp.status}`);
            if (resp.ok && resp.status !== 204) {
                const data = await resp.json();
                console.log(`✅ Success: ${ep}`);
                console.log("Keys:", Object.keys(data));
                console.log("Data:", JSON.stringify(data).substring(0, 500));
            }
        } catch (e) {
            console.log("Error:", e.message);
        }
    }
}

run();
