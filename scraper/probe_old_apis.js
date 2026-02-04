
const KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';

async function probe() {
    // 1. Unofficial Cricbuzz (Quota was 0, check reset?)
    const cbHost = 'unofficial-cricbuzz.p.rapidapi.com';
    const cricbuzzMatchId = '105825'; // Example ID (SL vs ENG is likely different here)
    // We don't have a valid ID handy, let's try List to check Quota
    console.log(`\n-- Checking Unofficial Cricbuzz --`);
    try {
        const r = await fetch(`https://${cbHost}/matches/list?matchState=live`, {
            headers: { 'x-rapidapi-key': KEY, 'x-rapidapi-host': cbHost }
        });
        console.log(`Status: ${r.status}`);
        console.log(`Quota Remaining: ${r.headers.get('x-ratelimit-requests-remaining')}`);
        // If 200, we might use it for squad!
    } catch (e) { console.log("CB Err:", e.message); }

    // 2. Free Cricbuzz (Backup)
    const freeHost = 'free-cricbuzz-cricket-api.p.rapidapi.com';
    console.log(`\n-- Checking Free Cricbuzz API --`);
    try {
        const r = await fetch(`https://${freeHost}/matches/v1/recent`, {
            headers: { 'x-rapidapi-key': KEY, 'x-rapidapi-host': freeHost }
        });
        console.log(`Status: ${r.status}`);
        const data = await r.json();
        // If matches found, we can maybe map names to find an ID for squad
    } catch (e) { console.log("Free CB Err:", e.message); }
}

probe();
