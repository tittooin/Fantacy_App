const axios = require('axios');

async function findMatch() {
    const options = {
        method: 'GET',
        url: 'https://free-cricbuzz-cricket-api.p.rapidapi.com/cricket-schedule',
        params: { type: 'recent' }, // Recent contains past 24h usually
        headers: {
            'x-rapidapi-key': '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee',
            'x-rapidapi-host': 'free-cricbuzz-cricket-api.p.rapidapi.com'
        }
    };

    try {
        console.log("Fetching...");
        const response = await axios.request(options);
        const schedules = response.data.schedules || [];

        let foundId = null;

        // Strategy 1: Look for 'matchScore' or 'score' object inside matchInfo
        // Strategy 2: Look for ANY match with endDate < now
        const now = Date.now();

        schedules.forEach(day => {
            const list = day.scheduleAdWrapper?.matchScheduleList || [];
            list.forEach(series => {
                const matches = series.matchInfo || [];
                matches.forEach(m => {
                    if (m.matchScore || m.isMatchComplete || parseInt(m.endDate) < now) {
                        console.log(`Potential Match: ${m.matchId} | End: ${m.endDate}`);
                        foundId = m.matchId;
                    }
                });
            });
        });

        if (foundId) {
            console.log(`Probing Scorecard /mcenter.v1.json for ID: ${foundId}`);
            try {
                const res = await axios.get(`https://free-cricbuzz-cricket-api.p.rapidapi.com/mcenter.v1.json?matchId=${foundId}`, { headers: options.headers });
                console.log("MCENTER RESULT:");
                console.log(JSON.stringify(res.data, null, 2).substring(0, 1000));
            } catch (e) { console.log("Mcenter failed"); }

            console.log(`Probing /cricket-livescores... (should overlap if active?)`);
            // verify livescores generally
        } else {
            console.log("Still no past match found. Trying specific ID 10000 just in case?");
        }

    } catch (error) {
        console.error(error);
    }
}

findMatch();
