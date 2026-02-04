
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'unofficial-cricbuzz.p.rapidapi.com';
const matchId = '121422';

async function run() {
    // 1. Get Scorecard
    const url = `https://${host}/matches/get-scorecard?matchId=${matchId}`;
    console.log(`Fetching Scorecard: ${url}`);

    const resp = await fetch(url, {
        headers: { 'x-rapidapi-key': RAPID_API_KEY, 'x-rapidapi-host': host }
    });

    if (resp.ok) {
        const data = await resp.json();
        console.log("------------------------------------------");
        console.log(JSON.stringify(data, null, 2));
        console.log("------------------------------------------");
    } else {
        console.log("Error:", resp.status);
    }
}

run();
