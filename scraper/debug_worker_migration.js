
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const HOST = 'livescore6.p.rapidapi.com';

// Mock ENV for DB
const env = {
    DB: {
        prepare: (sql) => ({
            all: async () => ({ results: [{ series_id: 23110 }] })
        })
    }
};

async function fetchMatchesFromAPI(key, host, env) {
    const primary = {
        host: host,
        endpointLive: '/matches/v2/list-live?Category=cricket',
        endpointDate: '/matches/v2/list-by-date?Category=cricket'
    };

    let parsed = [];

    // Fetch UPCOMING (Today/Tomorrow)
    try {
        const dates = [];
        const d = new Date();
        dates.push(d.toISOString().split('T')[0].replace(/-/g, '')); // Today
        d.setDate(d.getDate() + 1);
        dates.push(d.toISOString().split('T')[0].replace(/-/g, '')); // Tomorrow
        d.setDate(d.getDate() - 2);
        dates.push(d.toISOString().split('T')[0].replace(/-/g, '')); // Yesterday

        for (const dateStr of dates) {
            const url = `https://${primary.host}${primary.endpointDate}&Date=${dateStr}`;
            const resp = await fetch(url, {
                headers: { 'x-rapidapi-key': key, 'x-rapidapi-host': primary.host }
            });

            if (resp.ok) {
                const data = await resp.json();
                const schedMatches = parseMatches(data);
                console.log(`✅ Matches on ${dateStr}: ${schedMatches.length}`);
                if (schedMatches.length > 0) {
                    console.log("Sample Match Series ID:", schedMatches[0].seriesId);
                    console.log("Sample Match Title:", schedMatches[0].title);
                    console.log("Sample Match Team IDs:", schedMatches[0].team1Id, schedMatches[0].team2Id);
                }
                parsed = [...parsed, ...schedMatches];
            }
        }

    } catch (e) {
        console.error(`⚠️ Schedule API Failed: ${e.message}`);
    }
}

function parseMatches(data) {
    let matches = [];
    if (data.Stages && Array.isArray(data.Stages)) {
        data.Stages.forEach(stage => {
            const events = stage.Events || [];
            events.forEach(event => {
                const m = formatMatch(event, stage);
                if (m) matches.push(m);
            });
        });
    }
    return matches;
}

function parseLiveScoreDate(dateStr) {
    if (!dateStr) return Date.now();
    const str = dateStr.toString();
    if (str.length < 14) return Date.now();
    const y = str.substring(0, 4);
    const m = str.substring(4, 6);
    const d = str.substring(6, 8);
    const h = str.substring(8, 10);
    const min = str.substring(10, 12);
    const s = str.substring(12, 14);
    return new Date(`${y}-${m}-${d}T${h}:${min}:${s}Z`).getTime();
}

function formatMatch(event, stage) {
    if (!event || !event.T1 || !event.T2) return null;
    const t1 = event.T1[0] || {};
    const t2 = event.T2[0] || {};
    const mId = event.Eid;
    const sDate = parseLiveScoreDate(event.Esd);

    if (!mId || !t1.Nm || !t2.Nm) return null;

    return {
        id: mId.toString(),
        seriesId: (stage.Sid || '0').toString(),
        seriesName: stage.Snm || stage.Cnm || 'Unknown Series',
        title: `${t1.Nm} vs ${t2.Nm}`,
        team1Name: t1.Nm,
        team2Name: t2.Nm,
        team1Id: (t1.ID || '0').toString(),
        team2Id: (t2.ID || '0').toString(),
    };
}

fetchMatchesFromAPI(RAPID_API_KEY, HOST, env);
