
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';

const hosts = [
    'free-cricbuzz-cricket-api.p.rapidapi.com',
    'free-cricbuzz-cricket-api1.p.rapidapi.com',
    'cricbuzz-cricket.p.rapidapi.com',
    'cricket-api.p.rapidapi.com',
    'cricket-live-data.p.rapidapi.com'
];

const eps = ['/matches', '/matches/upcoming', '/matches/list'];

async function test() {
    for (const h of hosts) {
        console.log(`\n--- Host: ${h} ---`);
        for (const ep of eps) {
            try {
                const url = `https://${h}${ep}`;
                const response = await fetch(url, {
                    headers: {
                        'x-rapidapi-key': RAPID_API_KEY,
                        'x-rapidapi-host': h,
                        'User-Agent': 'Mozilla/5.0'
                    }
                });

                console.log(`[${response.status}] ${ep}`);
                if (response.ok) {
                    const data = await response.json();
                    const keys = Object.keys(data);
                    console.log(`   Keys: ${keys.join(', ')}`);
                    if (data.schedules) console.log('   ✅ HAS SCHEDULES!');
                    if (data.typeMatches) console.log('   ✅ HAS TYPEMATCHES!');
                } else if (response.status !== 404) {
                    const text = await response.text();
                    console.log(`   Msg: ${text.substring(0, 50)}`);
                }
            } catch (e) {
                // console.log(`   Err: ${e.message}`);
            }
            await new Promise(r => setTimeout(r, 1500));
        }
    }
}

test();
