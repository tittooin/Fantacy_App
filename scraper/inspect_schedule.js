
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'free-cricbuzz-cricket-api.p.rapidapi.com';

async function run() {
    console.log(`🔍 Inspecting /cricket-schedule data...\n`);
    try {
        const res = await fetch(`https://${host}/cricket-schedule`, {
            headers: {
                'x-rapidapi-key': RAPID_API_KEY,
                'x-rapidapi-host': host,
                'User-Agent': 'Mozilla/5.0'
            }
        });
        if (res.ok) {
            const data = await res.json();
            console.log(JSON.stringify(data, null, 2).substring(0, 3000));
        } else {
            console.log(`Error: ${res.status}`);
        }
    } catch (e) {
        console.log(`Error: ${e.message}`);
    }
}
run();
