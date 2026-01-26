/**
 * Test API with 2-second delay
 */

const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const RAPID_API_HOST = 'free-cricbuzz-cricket-api1.p.rapidapi.com';

async function test() {
    console.log(`📡 Testing ${RAPID_API_HOST} with 2s delay...`);

    for (let i = 0; i < 3; i++) {
        try {
            const url = `https://${RAPID_API_HOST}/matches`;
            const response = await fetch(url, {
                headers: {
                    'x-rapidapi-key': RAPID_API_KEY,
                    'x-rapidapi-host': RAPID_API_HOST
                }
            });

            console.log(`[${response.status}] Request ${i + 1}`);
            if (response.ok) {
                const data = await response.json();
                console.log(`   ✅ Success! Found matches: ${data.typeMatches ? 'Yes' : 'No'}`);
            } else {
                const text = await response.text();
                console.log(`   ❌ Error: ${text.substring(0, 100)}`);
            }
        } catch (e) {
            console.error(e.message);
        }
        await new Promise(r => setTimeout(r, 2000));
    }
}

test();
