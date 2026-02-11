// Check D1 database directly for squad data
const WORKER_URL = 'https://fantasy-cricket-api.moremagical4.workers.dev';

async function checkD1Squad(matchId) {
    console.log(`\n🔍 Checking D1 Database for Match: ${matchId}\n`);

    try {
        // Try to get match info first
        const matchUrl = `${WORKER_URL}/api/matches`;
        console.log('📡 Fetching matches...');
        const matchResp = await fetch(matchUrl);
        const matchData = await matchResp.json();

        if (matchData.success && matchData.matches) {
            const match = matchData.matches.find(m => m.id === matchId || m.id === parseInt(matchId));
            if (match) {
                console.log('\n✅ Match Found in D1:');
                console.log('  - ID:', match.id);
                console.log('  - Teams:', match.team_a, 'vs', match.team_b);
                console.log('  - Status:', match.status);
                console.log('  - Series ID:', match.series_id);
            } else {
                console.log('\n❌ Match NOT found in D1 database!');
                console.log('Available match IDs:', matchData.matches.map(m => m.id).slice(0, 10));
            }
        }

        // Now try squad endpoint without force
        console.log('\n📡 Checking cached squad data...');
        const squadUrl = `${WORKER_URL}/api/squads?matchId=${matchId}`;
        const squadResp = await fetch(squadUrl);
        const squadData = await squadResp.json();

        console.log('\n📦 Cached Squad Response:');
        console.log('  - success:', squadData.success);
        console.log('  - source:', squadData.source);
        console.log('  - error:', squadData.error);
        console.log('  - teamA players:', squadData.teamA?.length || 0);
        console.log('  - teamB players:', squadData.teamB?.length || 0);

        // Try with force=true
        console.log('\n📡 Trying force refresh...');
        const forceUrl = `${WORKER_URL}/api/squads?matchId=${matchId}&force=true`;
        const forceResp = await fetch(forceUrl);
        const forceData = await forceResp.json();

        console.log('\n📦 Force Refresh Response:');
        console.log('  - success:', forceData.success);
        console.log('  - source:', forceData.source);
        console.log('  - error:', forceData.error);

        if (forceData.error) {
            console.log('\n❌ Error Details:', forceData.error);
            console.log('\n💡 Possible Causes:');
            console.log('  1. Match not in D1 database');
            console.log('  2. RapidAPI rate limit exceeded');
            console.log('  3. RapidAPI returning 204/empty for this match');
            console.log('  4. Series ID missing or incorrect');
        }

    } catch (error) {
        console.error('\n❌ Error:', error.message);
    }
}

const matchId = process.argv[2] || '113094';
checkD1Squad(matchId);
