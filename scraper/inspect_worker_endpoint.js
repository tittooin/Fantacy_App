
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'unofficial-cricbuzz.p.rapidapi.com';

async function run() {
    console.log(`🔍 Inspecting worker endpoint: /matches/get-schedules ...\n`);
    try {
        const url = `https://${host}/matches/get-schedules?matchtype=international`;
        console.log(`Fetching: ${url}`);
        const res = await fetch(url, {
            headers: {
                'x-rapidapi-key': RAPID_API_KEY,
                'x-rapidapi-host': host,
                'User-Agent': 'Mozilla/5.0'
            }
        });
        if (res.ok) {
            const data = await res.json();
            console.log("Keys:", Object.keys(data));
            console.log(JSON.stringify(data, null, 2).substring(0, 3000));
        } else {
            console.log(`Error: ${res.status}`);
        }
    } catch (e) {
        console.log(`Error: ${e.message}`);
    }
}
run();
