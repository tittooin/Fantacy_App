/**
 * Ultimate host search
 */

const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';

const hosts = [
    'free-cricbuzz-cricket-api.p.rapidapi.com',
    'free-cricbuzz-cricket-api1.p.rapidapi.com',
    'cricbuzz-cricket.p.rapidapi.com',
    'cricket-api.p.rapidapi.com',
    'cricket-live-data.p.rapidapi.com',
    'cricbuzz-api.p.rapidapi.com',
    'cricket-v1.p.rapidapi.com',
    'free-cricket.p.rapidapi.com',
    'free-cricbuzz.p.rapidapi.com'
];

async function test() {
    for (const h of hosts) {
        try {
            const url = `https://${h}/matches/list`;
            const response = await fetch(url, {
                headers: {
                    'x-rapidapi-key': RAPID_API_KEY,
                    'x-rapidapi-host': h
                }
            });
            console.log(`[${response.status}] ${h}`);
            if (response.status !== 404 && response.status !== 500) {
                const text = await response.text();
                console.log(`   Body: ${text.substring(0, 50)}`);
            }
        } catch (e) {
            // console.log(`   Error: ${e.message}`);
        }
        await new Promise(r => setTimeout(r, 1000));
    }
}

test();
