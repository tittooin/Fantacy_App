
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'free-cricbuzz-cricket-api.p.rapidapi.com';

const endpoints = [
    '/cricket-upcoming',
    '/cricket-recent',
    '/cricket-live',
    '/cricket-fixtures', // Re-testing just in case
    '/cricket-matches',
    '/cricket-list',
    '/cricket-schedule',
    '/cricket-match-schedule'
];

async function run() {
    console.log(`🚀 Probing ${host} - SHORT NAMES...\n`);
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
