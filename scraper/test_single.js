/**
 * Test api1 with slow requests
 */

const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const RAPID_API_HOST = 'free-cricbuzz-cricket-api1.p.rapidapi.com';

async function test() {
    console.log(`📡 Testing ${RAPID_API_HOST} with long delay...`);

    try {
        const url = `https://${RAPID_API_HOST}/matches`;
        const response = await fetch(url, {
            headers: {
                'x-rapidapi-key': RAPID_API_KEY,
                'x-rapidapi-host': RAPID_API_HOST
            }
        });

        console.log(`[${response.status}] Status`);
        if (response.ok) {
            const data = await response.json();
            console.log('✅ Success! Data keys:', Object.keys(data).join(', '));
        } else {
            const text = await response.text();
            console.log('❌ Error:', text);
        }
    } catch (e) {
        console.error('💥 Exception:', e.message);
    }
}

test();
