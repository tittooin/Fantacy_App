/**
 * Broad discovery on free-cricbuzz-cricket-api
 */

const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'free-cricbuzz-cricket-api.p.rapidapi.com';

const patterns = [
    '/matches/list',
    '/matches/live',
    '/matches/recent',
    '/matches/upcoming',
    '/m_matches/list',
    '/cricbuzz/v1/matches',
    '/cricbuzz/v1/matches/list',
    '/cricbuzz/v1/matches/live',
    '/img/v1/i1/c1/i.jpg',
    '/matches/v1/list',
    '/matches/v1/recent',
    '/matches/v1/upcoming',
    '/matches/v1/live',
];

async function test() {
    console.log(`🔍 Broad testing on ${host}...`);
    for (const p of patterns) {
        try {
            const response = await fetch(`https://${host}${p}`, {
                headers: {
                    'x-rapidapi-key': RAPID_API_KEY,
                    'x-rapidapi-host': host
                }
            });
            console.log(`[${response.status}] ${p}`);
            if (response.ok) {
                console.log('   ✅ FOUND!');
                try {
                    const data = await response.json();
                    console.log('      Keys:', Object.keys(data).join(', '));
                } catch {
                    console.log('      (Not JSON)');
                }
            }
        } catch (e) {
            console.log(`   Error on ${p}: ${e.message}`);
        }
        await new Promise(r => setTimeout(r, 1000));
    }
}

test();
