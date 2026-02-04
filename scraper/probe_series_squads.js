
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const HOST = 'free-cricbuzz-cricket-api.p.rapidapi.com';
const SERIES_ID = '7688'; // Example ID, need to get real one from match info

async function probeSeries(seriesId) {
    const url = `https://${HOST}/series/get-squads?seriesId=${seriesId}`;
    console.log(`Probe: ${url}`);
    try {
        const resp = await fetch(url, { headers: { 'x-rapidapi-key': RAPID_API_KEY, 'x-rapidapi-host': HOST } });
        console.log(`Status: ${resp.status}`);
        if (resp.ok) {
            const json = await resp.json();
            console.log("Peek:", JSON.stringify(json, null, 2).substring(0, 500));
        }
    } catch (e) { console.log("Fail:", e.message); }
}

async function getSeriesId(matchId) {
    const url = `https://${HOST}/cricket-match-info?matchId=${matchId}`;
    try {
        const resp = await fetch(url, { headers: { 'x-rapidapi-key': RAPID_API_KEY, 'x-rapidapi-host': HOST } });
        if (resp.ok) {
            const data = await resp.json();
            const info = data.response?.matchInfo || data.matchInfo;
            // console.log("Match Info:", info);
            return info?.seriesId || info?.series?.id;
        }
    } catch (e) { }
    return null;
}

async function run() {
    const mId = '145464'; // IRE vs PAK
    const sId = await getSeriesId(mId);
    console.log(`Series ID for match ${mId} is ${sId}`);

    if (sId) await probeSeries(sId);
}

run();
