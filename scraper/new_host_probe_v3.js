
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'free-cricbuzz-cricket-api.p.rapidapi.com';

const endpoints = [
    '/cricket-fixture',
    '/cricket-fixtures-list',
    '/cricket-match-fixtures',
    '/cricket-upcoming-matches',
    '/cricket-recent-matches',
    '/cricket-live-matches',
    '/cricket-matches-list',
    '/cricket-get-fixtures',
    '/cricket-match-schedules',
    '/cricket-schedules',
    '/cricket-live-match-score',
    '/cricket-scorecard',
    '/cricket-match-scorecard'
];

async function run() {
    console.log(`🚀 Probing ${host} - ROUND 2...\n`);
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
            }
        } catch (e) { }
        await new Promise(r => setTimeout(r, 1000));
    }
}
run();
