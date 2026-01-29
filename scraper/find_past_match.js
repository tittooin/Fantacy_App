const axios = require('axios');

async function findPastMatch() {
    const options = {
        method: 'GET',
        url: 'https://free-cricbuzz-cricket-api.p.rapidapi.com/cricket-schedule',
        params: { type: 'recent' },
        headers: {
            'x-rapidapi-key': '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee',
            'x-rapidapi-host': 'free-cricbuzz-cricket-api.p.rapidapi.com'
        }
    };

    try {
        console.log("Fetching recent schedule...");
        const response = await axios.request(options);
        const now = Date.now();
        let pastMatch = null;

        if (response.data.schedules) {
            for (const item of response.data.schedules) {
                if (item.scheduleAdWrapper && item.scheduleAdWrapper.matchScheduleList) {
                    for (const schedule of item.scheduleAdWrapper.matchScheduleList) {
                        for (const info of schedule.matchInfo) {
                            if (parseInt(info.endDate) < now) {
                                pastMatch = info;
                                break;
                            }
                        }
                        if (pastMatch) break;
                    }
                }
                if (pastMatch) break;
            }
        }

        if (pastMatch) {
            console.log(`Found Past Match: ${pastMatch.matchId} (${pastMatch.team1.teamSName} vs ${pastMatch.team2.teamSName})`);
            console.log("Probing scorecard for this match...");

            // Probe mcenter with this ID
            const probeRes = await axios.get(`https://free-cricbuzz-cricket-api.p.rapidapi.com/mcenter.v1.json`, {
                params: { matchId: pastMatch.matchId },
                headers: options.headers
            });
            console.log("SUCCESS /mcenter.v1.json:");
            console.log(JSON.stringify(probeRes.data, null, 2).substring(0, 2000));

        } else {
            console.log("No past match found in the 'recent' list.");
        }

    } catch (error) {
        console.error("Error:", error.message);
        if (error.response) console.log(error.response.status);
    }
}

findPastMatch();
