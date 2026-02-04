
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'unofficial-cricbuzz.p.rapidapi.com';
const teamId = '2'; // India

async function run() {
    console.log(`🔍 Probe Team Players for ID ${teamId}...\n`);
    const endpoints = [
        `/teams/get-players?teamId=${teamId}`,
        `/teams/get-squad?teamId=${teamId}`,
        `/players/list?teamId=${teamId}`
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
                console.log("Data:", JSON.stringify(data).substring(0, 500));
            }
        } catch (e) {
            console.log("Error:", e.message);
        }
    }
}

run();
