
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const HOST = 'free-cricbuzz-cricket-api.p.rapidapi.com';

async function debugMatchListIDs() {
    const url = `https://${HOST}/cricket-schedule`; // Backup API as Primary is 429
    console.log(`fetching: ${url}`);

    try {
        const resp = await fetch(url, { headers: { 'x-rapidapi-key': RAPID_API_KEY, 'x-rapidapi-host': HOST } });
        if (resp.ok) {
            const data = await resp.json();

            // Replicate Worker's parseMatches logic (Partial)
            const schedules = data.response?.schedules || [];

            schedules.forEach(s => {
                const wrapper = s.scheduleAdWrapper || {};
                const map = wrapper.matchScheduleMap || wrapper;
                const list = map.matchScheduleList || [];

                list.forEach(series => {
                    const matchesList = series.seriesMatches || series.matchInfo || [];
                    matchesList.forEach(mItem => {
                        let info = mItem.matchInfo || mItem;
                        if (info && (info.matchId == 145464 || info.matchId == '145464')) {
                            console.log("\n--- Target Match 145464 Found ---");
                            console.log(JSON.stringify(info, null, 2));

                            // Test Extraction Logic
                            const t1Name = info.team1?.teamName || info.team1?.name || info.team1?.sName || 'Team 1';
                            const t2Name = info.team2?.teamName || info.team2?.name || info.team2?.sName || 'Team 2';

                            const t1Id = (info.team1?.teamId || info.team1?.id || 0).toString();
                            const t2Id = (info.team2?.teamId || info.team2?.id || 0).toString();

                            console.log(`\nExtracted Names: ${t1Name} vs ${t2Name}`);
                            console.log(`Extracted IDs: ${t1Id} vs ${t2Id}`);
                        }
                    });
                });
            });
        } else {
            console.log("Fetch Failed:", resp.status);
        }
    } catch (e) { console.error("Error:", e.message); }
}

debugMatchListIDs();
