const fs = require('fs');

async function verify() {
    try {
        const response = await fetch('https://fantasy-cricket-api.moremagical4.workers.dev/api/squads?matchId=139252');
        const data = await response.json();

        if (!data.success) {
            console.log("❌ API Success False:", data);
            return;
        }

        console.log(`✅ Source: ${data.source}`);

        analyzeTeam("Team A", data.teamA);
        analyzeTeam("Team B", data.teamB);

    } catch (e) {
        console.error("Fetch Error:", e);
    }
}

function analyzeTeam(name, players) {
    console.log(`\n--- ${name} Analysis ---`);
    console.log(`Total Players: ${players.length}`);

    const roles = { WK: 0, BAT: 0, AR: 0, BOWL: 0, UNKNOWN: 0 };
    const missingFields = [];

    players.forEach(p => {
        // Count Roles
        if (roles[p.role] !== undefined) roles[p.role]++;
        else {
            roles['UNKNOWN']++;
            console.log(`⚠️ Unknown Role: ${p.role} (Player: ${p.name})`);
        }

        // Check Critical Fields for Flutter
        if (!p.id) missingFields.push(`${p.name} (id)`);
        if (!p.name) missingFields.push(`${p.id} (name)`);
        if (typeof p.credits !== 'number') missingFields.push(`${p.name} (credits type: ${typeof p.credits})`);
        if (typeof p.fantasy_rating !== 'number') console.log(`ℹ️ Note: ${p.name} rating is ${typeof p.fantasy_rating}`);

        // Image Check (Flutter might hide if 404?)
        if (!p.imageUrl) console.log(`ℹ️ No Image: ${p.name}`);
    });

    console.log("Role Counts:", roles);
    if (missingFields.length > 0) {
        console.log("❌ Potential Parsing Issues:", missingFields);
    } else {
        console.log("✅ Data Structure OK");
    }
}

verify();
