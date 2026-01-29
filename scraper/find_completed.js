const axios = require('axios');

async function findCompletedMatches() {
    const types = ['completed', 'history', 'results', 'past'];

    for (const type of types) {
        console.log(`Testing type=${type}...`);
        const options = {
            method: 'GET',
            url: 'https://free-cricbuzz-cricket-api.p.rapidapi.com/cricket-schedule',
            params: { type },
            headers: {
                'x-rapidapi-key': '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee',
                'x-rapidapi-host': 'free-cricbuzz-cricket-api.p.rapidapi.com'
            }
        };

        try {
            const response = await axios.request(options);
            // Check if we got any data
            const dataStr = JSON.stringify(response.data);
            if (dataStr.length > 500 && !dataStr.includes("Endpoint '") && response.data.schedules) {
                console.log(`✅ SUCCESS type=${type}`);
                // Extract first match ID
                const firstMatch = response.data.schedules[0]?.scheduleAdWrapper?.matchScheduleList[0]?.matchInfo[0];
                if (firstMatch) {
                    console.log(`Match ID: ${firstMatch.matchId}`);
                    // Probe mcenter
                    const probe = await axios.get(`https://free-cricbuzz-cricket-api.p.rapidapi.com/mcenter.v1.json?matchId=${firstMatch.matchId}`, { headers: options.headers });
                    console.log("MCenter Probe Result:");
                    console.log(JSON.stringify(probe.data, null, 2).substring(0, 500));
                }
                return;
            } else {
                console.log(`❌ Empty/Invalid for type=${type}`);
            }
        } catch (error) {
            // console.error(error.message);
        }
    }
}

findCompletedMatches();
