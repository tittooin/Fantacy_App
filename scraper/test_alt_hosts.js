/**
 * Test multiple plausible hosts
 */

const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';

const hosts = [
    'cricbuzz-cricket.p.rapidapi.com',
    'cricket-api.p.rapidapi.com',
    'cricket-live-data.p.rapidapi.com',
    'free-cricbuzz-cricket-api-v1.p.rapidapi.com'
];

async function testHost(host) {
    try {
        const url = `https://${host}/matches/list`;
        const response = await fetch(url, {
            headers: {
                'x-rapidapi-key': RAPID_API_KEY,
                'x-rapidapi-host': host
            }
        });

        console.log(`[${response.status}] ${host}`);
        if (response.ok) {
            const data = await response.json();
            console.log(`   ✅ Success! Keys: ${Object.keys(data).join(', ')}`);
            return true;
        }
    } catch (e) {
        // console.error(e.message);
    }
    return false;
}

async function main() {
    for (const host of hosts) {
        await testHost(host);
        await new Promise(r => setTimeout(r, 500));
    }
}

main();
