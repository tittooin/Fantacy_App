
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';

// Replicate fetchMatchesFromAPI logic EXACTLY
async function fetchMatchesFromAPI(key) {
    // Hosts Config
    const primary = {
        host: 'unofficial-cricbuzz.p.rapidapi.com',
        endpoint: '/matches/get-schedules?matchtype=international'
    };
    const backup = {
        host: 'free-cricbuzz-cricket-api.p.rapidapi.com',
        endpoint: '/cricket-schedule'
    };

    let parsed = [];

    // 1. Try Primary
    try {
        console.log(`📡 Fetching Primary: https://${primary.host}${primary.endpoint}`);
        const resp = await fetch(`https://${primary.host}${primary.endpoint}`, {
            headers: { 'x-rapidapi-key': key, 'x-rapidapi-host': primary.host }
        });

        if (resp.ok) {
            const data = await resp.json();
            // console.log("Primary Data Keys:", Object.keys(data));
            parsed = parseMatches(data);
            if (parsed.length > 0) {
                console.log(`✅ Primary API Success: ${parsed.length} matches`);
            } else {
                console.log("⚠️ Primary returned 0 matches (Empty List)");
                throw new Error("Primary returned 0 matches");
            }
        } else {
            console.log(`❌ Primary API Error: ${resp.status}`);
            throw new Error(`Primary API Error: ${resp.status}`);
        }
    } catch (e) {
        console.error(`⚠️ Primary Failed: ${e.message}. Trying Backup...`);

        // 2. Try Backup
        try {
            console.log(`📡 Fetching Backup: https://${backup.host}${backup.endpoint}`);
            const resp = await fetch(`https://${backup.host}${backup.endpoint}`, {
                headers: { 'x-rapidapi-key': key, 'x-rapidapi-host': backup.host }
            });

            if (resp.ok) {
                const data = await resp.json();
                console.log("Backup Data:", JSON.stringify(data, null, 2).substring(0, 3000));
                parsed = parseMatches(data);
                console.log(`✅ Backup API Success: ${parsed.length} matches`);
            } else {
                console.error(`❌ Backup API Error: ${resp.status}`);
            }
        } catch (e2) {
            console.error(`❌ Backup API Failed: ${e2.message}`);
        }
    }

    return parsed;
}

function parseMatches(data) {
    let matches = [];

    // Helper to process scheduleAdWrapper
    const processWrapper = (wrapper) => {
        if (!wrapper) return;

        // Flexible Access: Check for map OR direct list
        const map = wrapper.matchScheduleMap || wrapper;
        const list = map.matchScheduleList;

        if (list && Array.isArray(list)) {
            list.forEach(series => {
                const matchesList = series.seriesMatches || series.matchInfo || [];
                if (Array.isArray(matchesList)) {
                    matchesList.forEach(mItem => {
                        let info = mItem.matchInfo || mItem;
                        if (info) {
                            const m = {
                                id: info.matchId || info.id,
                                team1: info.team1?.teamName,
                                team2: info.team2?.teamName,
                                status: info.status,
                                date: info.startDate
                            };
                            if (m.id) matches.push(m);
                        }
                    });
                }
            });
        }
    };

    // Structure 1: Backup API (Wrapped in response.schedules)
    if (data.response && data.response.schedules && Array.isArray(data.response.schedules)) {
        console.log("Parser: Detected Backup API Structure (response.schedules)");
        data.response.schedules.forEach(item => {
            processWrapper(item.scheduleAdWrapper);
        });
    }
    // Structure 2: Primary API (Direct at Root)
    else if (data.scheduleAdWrapper) {
        if (Array.isArray(data.scheduleAdWrapper)) {
            data.scheduleAdWrapper.forEach(processWrapper);
        } else {
            processWrapper(data.scheduleAdWrapper);
        }
    }
    // Fallback: Check 'matchScheduleMap' directly
    else if (data.matchScheduleMap) {
        processWrapper({ matchScheduleMap: data.matchScheduleMap });
    }

    return matches;
}

// Run
fetchMatchesFromAPI(RAPID_API_KEY).then(matches => console.log("Final Matches:", matches.length));
