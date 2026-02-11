// Simple test to check if Worker is responding at all
const WORKER_URL = 'https://fantasy-cricket-api.moremagical4.workers.dev';

async function testWorker() {
    console.log('\n🔍 Testing Worker Endpoints\n');

    // Test 1: Health check
    try {
        console.log('1️⃣ Testing /api/matches...');
        const matchResp = await fetch(`${WORKER_URL}/api/matches`);
        const matchData = await matchResp.json();
        console.log('   Status:', matchResp.status);
        console.log('   Success:', matchData.success);
        console.log('   Matches:', matchData.matches?.length || 0);

        if (matchData.matches && matchData.matches.length > 0) {
            console.log('\n📋 Available Matches:');
            matchData.matches.slice(0, 5).forEach(m => {
                console.log(`   - ID: ${m.id}, ${m.team_a} vs ${m.team_b}, Status: ${m.status}`);
            });
        }
    } catch (e) {
        console.error('   ❌ Error:', e.message);
    }

    // Test 2: Try a different match
    try {
        console.log('\n2️⃣ Testing /api/squads with a live match...');
        const matchResp = await fetch(`${WORKER_URL}/api/matches`);
        const matchData = await matchResp.json();

        if (matchData.matches && matchData.matches.length > 0) {
            // Find a live or upcoming match
            const testMatch = matchData.matches.find(m => m.status === 'Live' || m.status === 'Upcoming');

            if (testMatch) {
                console.log(`   Testing with Match ID: ${testMatch.id} (${testMatch.team_a} vs ${testMatch.team_b})`);
                const squadResp = await fetch(`${WORKER_URL}/api/squads?matchId=${testMatch.id}`);
                const squadData = await squadResp.json();
                console.log('   Success:', squadData.success);
                console.log('   Source:', squadData.source);
                console.log('   Team A:', squadData.teamA?.length || 0, 'players');
                console.log('   Team B:', squadData.teamB?.length || 0, 'players');

                if (squadData.teamA && squadData.teamA.length > 0) {
                    const player = squadData.teamA[0];
                    console.log('\n   📋 Sample Player:');
                    console.log('      - Name:', player.name);
                    console.log('      - Team Short Name:', player.teamShortName || '❌ MISSING');
                    console.log('      - Image URL:', player.imageUrl || '❌ MISSING');
                }
            }
        }
    } catch (e) {
        console.error('   ❌ Error:', e.message);
    }
}

testWorker();
