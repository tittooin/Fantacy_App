
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'unofficial-cricbuzz.p.rapidapi.com';
const matchId = '121422';

async function run() {
    // 1. Get Match Info
    const url = `https://${host}/matches/get-info?matchId=${matchId}`;
    console.log(`Fetching Match Info: ${url}`);

    try {
        const resp = await fetch(url, {
            headers: { 'x-rapidapi-key': RAPID_API_KEY, 'x-rapidapi-host': host }
        });

        if (resp.ok) {
            const data = await resp.json();
            console.log("------------------------------------------");
            console.log("Series ID:", data.seriesId);
            console.log("Team 1:", JSON.stringify(data.team1, null, 2));
            console.log("Team 2:", JSON.stringify(data.team2, null, 2));
            console.log("------------------------------------------");

            if (data.seriesId) {
                // If squads missing in match-info, check series-squads
                await checkSeriesSquads(data.seriesId);
            }
        } else {
            console.log("Error:", resp.status);
        }
    } catch (e) {
        console.error(e);
    }
}

async function checkSeriesSquads(seriesId) {
    const url = `https://${host}/series/get-squads?seriesId=${seriesId}`;
    console.log(`\nFetching Series Squads: ${url}`);
    const resp = await fetch(url, {
        headers: { 'x-rapidapi-key': RAPID_API_KEY, 'x-rapidapi-host': host }
    });
    if (resp.ok) {
        const data = await resp.json();
        console.log("Series Squad Data Keys:", Object.keys(data));
        console.log("Sample:", JSON.stringify(data).substring(0, 500));
    }
}

run();
