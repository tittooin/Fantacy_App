
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'unofficial-cricbuzz.p.rapidapi.com';
const squadId = '104426'; // India T20 Squad

async function run() {
    console.log(`🔍 Probing Squad Details for ID ${squadId}...\n`);
    const endpoints = [
        `/series/get-squad?squadId=${squadId}`,
        `/squads/get?squadId=${squadId}`,
        `/squads/get-players?squadId=${squadId}`,
        `/teams/get-squad?squadId=${squadId}`,
        `/series/get-players?squadId=${squadId}`
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
                console.log(`✅ Success: ${ep}`);
                console.log("Keys:", Object.keys(data));
                console.log("Sample:", JSON.stringify(data).substring(0, 200));
            }
        } catch (e) {
            console.log("Error:", e.message);
        }
    }
}

run();
