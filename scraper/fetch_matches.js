const axios = require('axios');

async function fetchMatches() {
    const options = {
        method: 'GET',
        url: 'https://free-cricbuzz-cricket-api.p.rapidapi.com/cricket-schedule',
        headers: {
            'x-rapidapi-key': '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee',
            'x-rapidapi-host': 'free-cricbuzz-cricket-api.p.rapidapi.com'
        }
    };

    try {
        const response = await axios.request(options);
        const data = response.data;
        const matches = [];

        if (data.schedules) {
            for (const item of data.schedules) {
                const day = item.scheduleAdWrapper || item;
                if (day.matchScheduleList) {
                    for (const schedule of day.matchScheduleList) {
                        const infos = schedule.matchInfo || [];
                        const list = Array.isArray(infos) ? infos : [infos];
                        list.forEach(i => matches.push({ id: i.matchId, name: `${i.team1?.teamSName} vs ${i.team2?.teamSName}` }));
                    }
                }
            }
        } else if (data.data) { // Some endpoints wrap in data
            // parse...
        }

        console.log("IDs:", matches.map(m => m.id).join(', '));
        console.log("Full List:", JSON.stringify(matches, null, 2));

    } catch (error) {
        console.error("Error:", error.message);
    }
}

fetchMatches();
