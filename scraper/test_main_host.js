/**
 * Test the main cricbuzz host
 */

const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'cricbuzz-cricket.p.rapidapi.com';

const endpoints = [
    '/matches/list',
    '/matches/v1/list'
];

async function test() {
    console.log(`📡 Testing main host ${host}...`);
    for (const ep of endpoints) {
        try {
            const response = await fetch(`https://${host}${ep}`, {
                headers: {
                    'x-rapidapi-key': RAPID_API_KEY,
                    'x-rapidapi-host': host
                }
            });
            console.log(`[${response.status}] ${ep}`);
            if (response.status !== 404) {
                const text = await response.text();
                console.log(`   Body: ${text.substring(0, 100)}`);
            }
        } catch (e) {
            console.log(`Error on ${ep}: ${e.message}`);
        }
    }
}

test();
