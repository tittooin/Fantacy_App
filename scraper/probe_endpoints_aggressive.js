
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const HOST = 'free-cricbuzz-cricket-api.p.rapidapi.com';
const TEAM_ID = '27'; // Ireland
const MATCH_ID = '145464';

async function probe(endpoint, params = {}) {
    const query = new URLSearchParams(params).toString();
    const url = `https://${HOST}${endpoint}?${query}`;
    console.log(`Probe: ${endpoint} -> ${url}`);
    try {
        const resp = await fetch(url, { headers: { 'x-rapidapi-key': RAPID_API_KEY, 'x-rapidapi-host': HOST } });
        console.log(`Status: ${resp.status}`);
        if (resp.ok) {
            const text = await resp.text();
            console.log("Peek:", text.substring(0, 500));
        }
    } catch (e) { console.log("Fail:", e.message); }
}

async function run() {
    await probe('/teams/get-players', { teamId: TEAM_ID });
    await probe('/cricket-team-squad', { teamId: TEAM_ID }); // Known fail, but trying again
    await probe('/cricket-squad', { matchId: MATCH_ID });
    await probe('/matches/get-squads', { matchId: MATCH_ID }); // Sometimes matches endpoint has it
}

run();
