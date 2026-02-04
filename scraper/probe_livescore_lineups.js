
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const HOST = 'livescore6.p.rapidapi.com';

async function probe(endpoint) {
    const url = `https://${HOST}${endpoint}`;
    console.log(`Probe: ${url}`);
    try {
        const resp = await fetch(url, { headers: { 'x-rapidapi-key': RAPID_API_KEY, 'x-rapidapi-host': HOST } });
        console.log(`Status: ${resp.status}`);
        if (resp.ok) {
            const json = await resp.json();
            // console.log("Response:", JSON.stringify(json).substring(0, 400));

            if (json.Lineups) {
                console.log("✅ Lineups Found!");
                console.log(JSON.stringify(json.Lineups, null, 2).substring(0, 500));
            } else {
                console.log("Keys:", Object.keys(json));
            }
        }
    } catch (e) { console.log("Err:", e.message); }
}

async function run() {
    const eid = '1637155'; // Use ID from previous scan
    await probe(`/matches/v2/get-lineups?Eid=${eid}&Category=cricket`);
    await probe(`/matches/v2/get-info?Eid=${eid}&Category=cricket`);
    await probe(`/matches/v2/details?Eid=${eid}&Category=cricket`); // Often details contain lineups
}

run();
