/**
 * Test host validity by hitting the root
 */

const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';

const hosts = [
    'free-cricbuzz-cricket-api.p.rapidapi.com',
    'free-cricbuzz-cricket-api1.p.rapidapi.com',
    'cricbuzz-cricket.p.rapidapi.com'
];

async function test() {
    for (const host of hosts) {
        try {
            const response = await fetch(`https://${host}/`, {
                headers: {
                    'x-rapidapi-key': RAPID_API_KEY,
                    'x-rapidapi-host': host
                }
            });
            console.log(`[${response.status}] ${host}`);
            const text = await response.text();
            console.log(`   Body: ${text.substring(0, 100)}`);
        } catch (e) {
            console.log(`   Error on ${host}: ${e.message}`);
        }
    }
}

test();
