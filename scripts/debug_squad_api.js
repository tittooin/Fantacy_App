// Debug script to check Worker API response in detail
const WORKER_URL = 'https://fantasy-cricket-api.moremagical4.workers.dev';

async function debugSquadAPI(matchId) {
    console.log(`\n🔍 Debugging Squad API for Match: ${matchId}\n`);

    try {
        const url = `${WORKER_URL}/api/squads?matchId=${matchId}&force=true`;
        console.log('📡 Calling:', url);

        const response = await fetch(url);
        console.log('\n📊 Response Status:', response.status, response.statusText);
        console.log('📊 Response Headers:', Object.fromEntries(response.headers.entries()));

        const data = await response.json();
        console.log('\n📦 Full Response Data:');
        console.log(JSON.stringify(data, null, 2));

        // Detailed analysis
        console.log('\n🔍 Analysis:');
        console.log('  - success:', data.success);
        console.log('  - source:', data.source);
        console.log('  - error:', data.error);
        console.log('  - teamA:', data.teamA ? `${data.teamA.length} players` : 'null/undefined');
        console.log('  - teamB:', data.teamB ? `${data.teamB.length} players` : 'null/undefined');

        if (data.teamA && data.teamA.length > 0) {
            console.log('\n📋 Sample Team A Player:');
            console.log(JSON.stringify(data.teamA[0], null, 2));
        }

        if (data.teamB && data.teamB.length > 0) {
            console.log('\n📋 Sample Team B Player:');
            console.log(JSON.stringify(data.teamB[0], null, 2));
        }

        return data;
    } catch (error) {
        console.error('\n❌ Error:', error.message);
        console.error('Stack:', error.stack);
    }
}

// Get matchId from command line
const matchId = process.argv[2] || '113094';
debugSquadAPI(matchId);
