
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'unofficial-cricbuzz.p.rapidapi.com';

async function run() {
    console.log(`🔍 Debugging Worker Logic Locally...\n`);
    const resp = await fetch(`https://${host}/matches/get-schedules?matchtype=international`, {
        headers: {
            'x-rapidapi-key': RAPID_API_KEY,
            'x-rapidapi-host': host,
            'User-Agent': 'Mozilla/5.0'
        }
    });

    if (resp.ok) {
        const data = await resp.json();
        // Mimic Worker Parse
        const matches = parseMatches(data);
        console.log(`✅ Parsed ${matches.length} matches.`);

        // Mimic Work Filter
        const unique = new Map();
        const now = Date.now();
        matches.forEach(m => {
            const isLive = m.status === 'Live' || m.status === 'In Progress';
            const isFuture = m.startTime > now;
            const diff = now - m.startTime;
            const isRecent = diff < 86400000; // 24 hours

            console.log(`Match ${m.team1ShortName} vs ${m.team2ShortName}: Start=${m.startDate} (Diff=${diff}ms). Accepted? ${isLive || isFuture || isRecent}`);

            if (isLive || m.status === 'In Progress' || m.startTime > now || (now - m.startTime) < 86400000) {
                unique.set(m.id, m);
            }
        });

        console.log(`✅ Final Filtered Count: ${unique.size}`);
        console.log("Entries:", Array.from(unique.values()));

    } else {
        console.log("API Error:", resp.status);
    }
}

// COPIED FROM cricket_engine.js with strict logging
function parseMatches(data) {
    let matches = [];

    if (data.scheduleAdWrapper && Array.isArray(data.scheduleAdWrapper)) {
        data.scheduleAdWrapper.forEach(dayWrapper => {
            const map = dayWrapper.matchScheduleMap;
            if (map && map.matchScheduleList) {
                map.matchScheduleList.forEach(series => {
                    const list = series.seriesMatches || series.matchInfo || [];
                    if (Array.isArray(list)) {
                        list.forEach(mItem => {
                            let info = mItem.matchInfo || mItem;
                            if (info) {
                                const m = formatMatch(info);
                                if (m) matches.push(m);
                            }
                        });
                    }
                });
            }
        });
    }
    return matches;
}

function formatMatch(info) {
    // STRICT VALIDATION COPY
    const t1Name = info.team1?.teamName || info.team1?.teamSName;
    const t2Name = info.team2?.teamName || info.team2?.teamSName;
    const mId = info.matchId || info.id;
    const sDate = info.startDate ? parseInt(info.startDate) : 0;

    if (!t1Name || !t2Name || !mId || !sDate) {
        console.log(`⚠️ Identifying Ghost Match: ID=${mId}, T1=${t1Name}, T2=${t2Name}, Date=${sDate}`);
        // Log Raw info if ghost
        // console.log(JSON.stringify(info));
        return null;
    }

    return {
        id: mId.toString(),
        team1ShortName: info.team1?.teamSName || 'T1',
        team2ShortName: info.team2?.teamSName || 'T2',
        startDate: sDate,
        status: info.status || info.state || 'Upcoming',
    };
}

run();
