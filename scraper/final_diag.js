
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const hosts = ['free-cricbuzz-cricket-api.p.rapidapi.com', 'free-cricbuzz-cricket-api1.p.rapidapi.com'];
const eps = ['/matches/list', '/matches/upcoming', '/matches'];

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
                    console.log(`   ✅ SUCCESS! Keys: ${Object.keys(data).join(', ')}`);
                }
            } catch (e) { }
            await new Promise(r => setTimeout(r, 2000));
        }
    }
}

test();
