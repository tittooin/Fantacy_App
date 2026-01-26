
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'free-cricbuzz-cricket-api.p.rapidapi.com';

async function test(ep) {
    console.log(`\nTesting ${ep} on ${host}...`);
    try {
        const response = await fetch(`https://${host}${ep}`, {
            headers: {
                'x-rapidapi-key': RAPID_API_KEY,
                'x-rapidapi-host': host,
                'User-Agent': 'Mozilla/5.0'
            }
        });
        console.log(`Status: ${response.status}`);
        const text = await response.text();
        console.log(`Body: ${text.substring(0, 100)}`);
    } catch (e) {
        console.log('Error:', e.message);
    }
}

async function main() {
    await test('/matches');
    await new Promise(r => setTimeout(r, 2000));
    await test('/matches/list');
}

main();
