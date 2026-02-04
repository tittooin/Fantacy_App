
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'unofficial-cricbuzz.p.rapidapi.com';
const matchId = '121422'; // From screenshot

async function run() {
    console.log(`🔍 Probing Squad Endpoint for Match ${matchId}...\n`);
    const endpoints = [
        `/matches/get-squad?matchId=${matchId}`,
        `/get-squad?matchId=${matchId}`,
        `/squads/list?matchId=${matchId}`
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
            if (resp.ok) {
                const data = await resp.json();
                console.log("✅ Data Received! structure Keys:", Object.keys(data));
                console.log("Sample:", JSON.stringify(data).substring(0, 500));

                if (data.players) {
                    console.log("Found 'players' key. Is Array?", Array.isArray(data.players));
                }
                break; // Found it
            }
        } catch (e) {
            console.log("Error:", e.message);
        }
    }
}

run();
