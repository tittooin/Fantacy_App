
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const HOST = 'unofficial-cricbuzz.p.rapidapi.com'; // PRIMARY HOST

async function probePrimarySquad() {
    const url = `https://${HOST}/teams/get-players?teamId=27`; // Ireland
    console.log(`fetching: ${url}`);

    try {
        const resp = await fetch(url, { headers: { 'x-rapidapi-key': RAPID_API_KEY, 'x-rapidapi-host': HOST } });
        console.log(`Status: ${resp.status}`);
        console.log(`Remaining Requests: ${resp.headers.get('x-ratelimit-requests-remaining')}`);
        console.log(`Reset Time: ${resp.headers.get('x-ratelimit-requests-reset')}`);

        if (resp.ok) {
            const data = await resp.json();
            const players = data.player || [];
            console.log(`Success! Found ${players.length} players.`);
            if (players.length > 0) console.log(players[0]);
        } else {
            const text = await resp.text();
            console.log("Error Body:", text);
        }
    } catch (e) {
        console.log("Fetch Error:", e.message);
    }
}

probePrimarySquad();
