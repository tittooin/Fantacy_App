
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const hosts = [
    'free-cricbuzz-cricket-api-v1.p.rapidapi.com',
    'free-cricbuzz-cricket-api1.p.rapidapi.com',
    'free-cricbuzz-cricket-api.p.rapidapi.com',
    'cricbuzz-cricket.p.rapidapi.com',
    'cricbuzz-cricket.p.rapidapi.com',
    'cricket-api.p.rapidapi.com'
];

async function run() {
    for (const h of hosts) {
        console.log(`\n--- Host: ${h} ---`);
        const eps = ['/matches/list', '/matches/upcoming', '/matches'];
        for (const ep of eps) {
            try {
                const res = await fetch(`https://${h}${ep}`, {
                    headers: { 'x-rapidapi-key': RAPID_API_KEY, 'x-rapidapi-host': h }
                });
                console.log(`[${res.status}] ${ep}`);
                if (res.ok) {
                    const data = await res.json();
                    console.log(`   SUCCESS! Keys: ${Object.keys(data).slice(0, 3)}`);
                    break;
                } else if (res.status === 429) {
                    const body = await res.text();
                    console.log(`   429 Body: ${body}`);
                }
            } catch (e) { }
        }
        await new Promise(r => setTimeout(r, 1000));
    }
}
run();
