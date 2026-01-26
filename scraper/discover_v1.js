/**
 * Discover endpoints for the host WITHOUT '1'
 * Hindi: Host bina '1' ke liye endpoints dhundna
 */

const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const RAPID_API_HOST = 'free-cricbuzz-cricket-api.p.rapidapi.com';

const endpoints = [
    '/matches/list',
    '/matches/v1/list',
    '/matches/v1/recent',
    '/matches/v1/upcoming',
    '/matches/v1/live',
    '/m_matches/list',
    '/m_matches/recent',
    '/m_matches/upcoming',
    '/m_matches/live',
    '/cricbuzz/v1/matches',
    '/cricbuzz/v1/matches/list',
    '/cricbuzz/v1/matches/live',
    '/status',
    '/test'
];

async function testEndpoint(endpoint) {
    try {
        const url = `https://${RAPID_API_HOST}${endpoint}`;
        const response = await fetch(url, {
            headers: {
                'x-rapidapi-key': RAPID_API_KEY,
                'x-rapidapi-host': RAPID_API_HOST
            }
        });

        console.log(`[${response.status}] ${endpoint}`);
        if (response.ok) {
            const data = await response.json();
            console.log(`   ✅ Keys: ${Object.keys(data).join(', ')}`);
            return true;
        }
    } catch (e) {
        // console.error(e.message);
    }
    return false;
}

async function main() {
    console.log(`🔍 Testing endpoints on ${RAPID_API_HOST}...`);
    for (const ep of endpoints) {
        await testEndpoint(ep);
        await new Promise(r => setTimeout(r, 500));
    }
}

main();
