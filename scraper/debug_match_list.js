
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const HOST = 'free-cricbuzz-cricket-api.p.rapidapi.com';

async function auditMatchListStructure() {
    const url = `https://${HOST}/cricket-schedule`;
    console.log(`fetching: ${url}`);

    try {
        const resp = await fetch(url, { headers: { 'x-rapidapi-key': RAPID_API_KEY, 'x-rapidapi-host': HOST } });
        if (resp.ok) {
            const data = await resp.json();
            console.log("Response Keys:", Object.keys(data));

            // Navigate like the worker: response.schedules -> scheduleAdWrapper -> matchScheduleList
            const schedules = data.response?.schedules || [];
            let matchFound = false;

            schedules.forEach(s => {
                const wrapper = s.scheduleAdWrapper || {};
                const map = wrapper.matchScheduleMap || wrapper;
                const list = map.matchScheduleList || [];

                if (list.length > 0 && !matchFound) {
                    const firstSeries = list[0];
                    const matches = firstSeries.seriesMatches || firstSeries.matchInfo || [];
                    if (matches.length > 0) {
                        const m = matches[0].matchInfo || matches[0];
                        console.log("\n--- Sample Match Object (from Backup API) ---");
                        console.log(JSON.stringify(m, null, 2));

                        console.log("\n--- Team 1 Structure ---");
                        console.log(m.team1);

                        // Check for ID
                        const t1Id = m.team1?.teamId || m.team1?.id;
                        console.log(`\nDetected Team 1 ID: ${t1Id}`);
                        matchFound = true;
                    }
                }
            });
        }
    } catch (e) { console.error("Error:", e.message); }
}

auditMatchListStructure();
