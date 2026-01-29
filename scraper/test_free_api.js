/**
 * Test endpoints for 'Free Cricbuzz Cricket API'
 */

const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const RAPID_API_HOST = 'free-cricbuzz-cricket-api.p.rapidapi.com';

const endpoints = [
    '/matches',
    '/live-matches',
    '/recent-matches',
    '/upcoming-matches',
    '/series',
    '/scorecard',
    '/players',
    '/teams'
];

async function test() {
    console.log(`📡 Testing ${RAPID_API_HOST}...`);

    for (const ep of endpoints) {
        try {
            const url = `https://${RAPID_API_HOST}${ep}`;
            const response = await fetch(url, {
                headers: {
                    'x-rapidapi-key': RAPID_API_KEY,
                    'x-rapidapi-host': RAPID_API_HOST
                }
            });

            console.log(`[${response.status}] ${ep}`);
            if (response.ok) {
                const data = await response.json();
                console.log(`   ✅ Success! Keys: ${Object.keys(data).slice(0, 5).join(', ')}`);
            }
        } catch (e) { }
        await new Promise(r => setTimeout(r, 500));
    }
}

test();
