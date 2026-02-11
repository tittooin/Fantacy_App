// Test script to check squad data for a match
const WORKER_URL = 'https://fantasy-cricket-api.moremagical4.workers.dev';

async function testSquadData(matchId) {
    console.log(`\n🔍 Testing Squad Data for Match: ${matchId}\n`);

    try {
        const response = await fetch(`${WORKER_URL}/api/squads?matchId=${matchId}`);
        const data = await response.json();

        console.log('📊 API Response:');
        console.log('Success:', data.success);
        console.log('Source:', data.source);
        console.log('\n📋 Team A Players:', data.teamA?.length || 0);
        console.log('📋 Team B Players:', data.teamB?.length || 0);

        if (data.teamA && data.teamA.length > 0) {
            console.log('\n✅ Team A Sample:');
            console.log('  - Name:', data.teamA[0].name);
            console.log('  - Team:', data.teamA[0].teamShortName);
            console.log('  - Role:', data.teamA[0].role);
        }

        if (data.teamB && data.teamB.length > 0) {
            console.log('\n✅ Team B Sample:');
            console.log('  - Name:', data.teamB[0].name);
            console.log('  - Team:', data.teamB[0].teamShortName);
            console.log('  - Role:', data.teamB[0].role);
        }

        // Check if both teams have data
        if (!data.teamA || data.teamA.length === 0) {
            console.log('\n❌ ERROR: Team A has NO players!');
        }
        if (!data.teamB || data.teamB.length === 0) {
            console.log('\n❌ ERROR: Team B has NO players!');
        }

        // Show all unique team names
        const allPlayers = [...(data.teamA || []), ...(data.teamB || [])];
        const uniqueTeams = [...new Set(allPlayers.map(p => p.teamShortName))];
        console.log('\n🏏 Unique Teams Found:', uniqueTeams);

        return data;
    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

// Test with the match from screenshot (SL vs OMAN)
// Replace with actual matchId
const matchId = process.argv[2] || '113094'; // Default to a test match

testSquadData(matchId);
