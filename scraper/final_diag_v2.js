
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const hosts = [
    'free-cricbuzz-cricket-api1.p.rapidapi.com',
    'free-cricbuzz-cricket-api.p.rapidapi.com',
    'cricbuzz-cricket.p.rapidapi.com'
];
const paths = [
    '/matches/list',
    '/matches/upcoming',
    '/matches',
    '/live'
];

async function runDiag() {
    console.log('--- STARTING COMPREHENSIVE DIAG ---');
    for (const host of hosts) {
        console.log(`\nTesting Host: ${host}`);
        for (const path of paths) {
            try {
                const url = `https://${host}${path}`;
                const res = await fetch(url, {
                    headers: {
                        'x-rapidapi-key': RAPID_API_KEY,
                        'x-rapidapi-host': host,
                        'User-Agent': 'Mozilla/5.0'
                    }
                });

                console.log(`[${res.status}] ${path}`);
                if (res.status !== 404) {
                    console.log('   Remaining:', res.headers.get('x-ratelimit-requests-remaining'));
                    if (res.ok) {
                        const data = await res.json();
                        console.log('   ✅ SUCCESS! Keys:', Object.keys(data).join(', '));
                    } else {
                        const text = await res.text();
                        console.log('   Error Body:', text.substring(0, 100));
                    }
                }
            } catch (e) {
                console.log(`   💥 Error: ${e.message}`);
            }
            await new Promise(r => setTimeout(r, 1000));
        }
    }
}

runDiag();
