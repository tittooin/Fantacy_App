/**
 * Exhaustive endpoint search
 */

const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'free-cricbuzz-cricket-api.p.rapidapi.com';

const endpoints = [
    '/matches',
    '/matches-list',
    '/matches_list',
    '/matches/list',
    '/matches/v1/list',
    '/matches/v1/recent',
    '/matches/v1/live',
    '/matches/v1/upcoming',
    '/m_matches/list',
    '/m_matches/recent',
    '/m_matches/upcoming',
    '/cricbuzz/v1/matches',
    '/cricbuzz/v1/matches/list',
    '/cricbuzz/v2/matches',
    '/matches/current',
    '/live',
    '/schedule',
    '/series',
    '/recent',
    '/upcoming'
];

async function test() {
    console.log(`🔍 Exhaustive testing on ${host}...`);
    for (const ep of endpoints) {
        try {
            const response = await fetch(`https://${host}${ep}`, {
                headers: {
                    'x-rapidapi-key': RAPID_API_KEY,
                    'x-rapidapi-host': host
                }
            });

            if (response.status !== 404) {
                console.log(`[${response.status}] ${ep} - PROBABLE HIT!`);
                if (response.ok) {
                    const data = await response.json();
                    console.log('   ✅ Success! Keys:', Object.keys(data).join(', '));
                    return; // Stop if we find it
                }
            } else {
                // console.log(`[404] ${ep}`);
            }
        } catch (e) {
            // console.log(`Error on ${ep}: ${e.message}`);
        }
        await new Promise(r => setTimeout(r, 1000));
    }
}

test();
