
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'free-cricbuzz-cricket-api.p.rapidapi.com';

const endpoints = [
    '/fixtures',
    '/get-fixtures',
    '/matches',
    '/live-match-score',
    '/get-live-match-score',
    '/matches/upcoming',
    '/matches/list',
    '/cricket-match-info',
    '/series',
    '/get-series',
    '/all-teams',
    '/get-all-teams'
];

async function run() {
    console.log(`🚀 Testing Correct Host: ${host}\n`);
    for (const ep of endpoints) {
        try {
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
                console.log(`   ✅ SUCCESS! Keys: ${Object.keys(data).slice(0, 5).join(', ')}`);
            } else {
                const text = await res.text();
                console.log(`   Error: ${text.substring(0, 100)}`);
            }
        } catch (e) {
            console.log(`   💥 Fetch Error: ${e.message}`);
        }
        await new Promise(r => setTimeout(r, 1000));
    }
}
run();
