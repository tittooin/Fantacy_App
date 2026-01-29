
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'free-cricbuzz-cricket-api.p.rapidapi.com';

async function run() {
    console.log(`📡 testing Live Scores on ${host}...\n`);
    const endpoints = ['/cricket-match-info?matchId=141903', '/cricket-scorecard?matchId=141903'];

    for (const ep of endpoints) {
        try {
            console.log(`🔍 testing ${ep}...`);
            const res = await fetch(`https://${host}${ep}`, {
                headers: {
                    'x-rapidapi-key': RAPID_API_KEY,
                    'x-rapidapi-host': host,
                    'User-Agent': 'Mozilla/5.0'
                }
            });
            console.log(`[${res.status}] ${ep}`);
            if (res.ok) {
                const data = await res.json();
                console.log(`   ✅ Success! Keys: ${Object.keys(data.response || {}).join(', ')}`);
            }
        } catch (e) {
            console.log(`   Error: ${e.message}`);
        }
    }
}
run();
