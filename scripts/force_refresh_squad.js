// Force refresh squad data for a match to get updated teamShortName
const WORKER_URL = 'https://fantasy-cricket-api.moremagical4.workers.dev';

async function forceRefreshSquad(matchId) {
    console.log(`\n🔄 Force Refreshing Squad for Match: ${matchId}\n`);

    try {
        // Call with force=true to bypass cache
        const response = await fetch(`${WORKER_URL}/api/squads?matchId=${matchId}&force=true`);
        const data = await response.json();

        console.log('✅ Refresh Response:');
        console.log('Success:', data.success);
        console.log('Source:', data.source);
        console.log('Team A Players:', data.teamA?.length || 0);
        console.log('Team B Players:', data.teamB?.length || 0);

        // Check teamShortName field
        if (data.teamA && data.teamA.length > 0) {
            const sample = data.teamA[0];
            console.log('\n📋 Team A Sample Player:');
            console.log('  - Name:', sample.name);
            console.log('  - Team ID:', sample.teamId);
            console.log('  - Team Short Name:', sample.teamShortName || '❌ MISSING');
            console.log('  - Role:', sample.role);
        }

        if (data.teamB && data.teamB.length > 0) {
            const sample = data.teamB[0];
            console.log('\n📋 Team B Sample Player:');
            console.log('  - Name:', sample.name);
            console.log('  - Team ID:', sample.teamId);
            console.log('  - Team Short Name:', sample.teamShortName || '❌ MISSING');
            console.log('  - Role:', sample.role);
        }

        // Verify all players have teamShortName
        const allPlayers = [...(data.teamA || []), ...(data.teamB || [])];
        const missingTeamName = allPlayers.filter(p => !p.teamShortName);

        if (missingTeamName.length > 0) {
            console.log(`\n⚠️ WARNING: ${missingTeamName.length} players missing teamShortName!`);
        } else {
            console.log('\n✅ All players have teamShortName field!');
        }

        // Show unique team names
        const uniqueTeams = [...new Set(allPlayers.map(p => p.teamShortName).filter(Boolean))];
        console.log('\n🏏 Teams Found:', uniqueTeams.join(' vs '));

        return data;
    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

// Get matchId from command line
const matchId = process.argv[2];

if (!matchId) {
    console.log('Usage: node scripts/force_refresh_squad.js <MATCH_ID>');
    console.log('Example: node scripts/force_refresh_squad.js 113094');
    process.exit(1);
}

forceRefreshSquad(matchId);
