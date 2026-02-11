// Find the correct match ID from available matches
const WORKER_URL = 'https://fantasy-cricket-api.moremagical4.workers.dev';

async function findMatches() {
    console.log('\n🔍 Finding Available Matches\n');

    try {
        const response = await fetch(`${WORKER_URL}/api/matches`);
        const data = await response.json();

        if (data.success && data.matches) {
            console.log(`✅ Found ${data.matches.length} total matches\n`);

            // Filter for SL vs OMAN or recent matches
            const slOmanMatches = data.matches.filter(m =>
                (m.team_a?.includes('SL') || m.team_a?.includes('Sri Lanka') ||
                    m.team_b?.includes('SL') || m.team_b?.includes('Sri Lanka')) &&
                (m.team_a?.includes('OMAN') || m.team_a?.includes('Oman') ||
                    m.team_b?.includes('OMAN') || m.team_b?.includes('Oman'))
            );

            if (slOmanMatches.length > 0) {
                console.log('🏏 SL vs OMAN Matches Found:');
                slOmanMatches.forEach(m => {
                    console.log(`   - ID: ${m.id}, ${m.team_a} vs ${m.team_b}, Status: ${m.status}, Start: ${new Date(m.start_time).toLocaleString()}`);
                });
            } else {
                console.log('⚠️ No SL vs OMAN matches found');
            }

            // Show recent upcoming/live matches
            console.log('\n📅 Recent Upcoming/Live Matches:');
            const recentMatches = data.matches
                .filter(m => m.status === 'Upcoming' || m.status === 'Live')
                .slice(0, 10);

            recentMatches.forEach(m => {
                console.log(`   - ID: ${m.id}, ${m.team_a} vs ${m.team_b}, Status: ${m.status}`);
            });

            // Test squad for first upcoming match
            if (recentMatches.length > 0) {
                const testMatch = recentMatches[0];
                console.log(`\n🧪 Testing Squad for Match ID: ${testMatch.id} (${testMatch.team_a} vs ${testMatch.team_b})`);

                const squadResp = await fetch(`${WORKER_URL}/api/squads?matchId=${testMatch.id}&force=true`);
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
                    console.log('      - Image URL:', player.imageUrl ? '✅ Present' : '❌ MISSING');
                }
            }

        } else {
            console.log('❌ Failed to fetch matches');
        }
    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

findMatches();
