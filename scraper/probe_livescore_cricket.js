
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
            console.log("Response Keys:", Object.keys(json));
            // Try to detect categories
            if (json.categories) console.log("Categories:", JSON.stringify(json.categories).substring(0, 300));
            if (endpoint.includes('cricket')) console.log("Content:", JSON.stringify(json).substring(0, 300));
        } else {
            console.log("Fail:", resp.status);
        }
    } catch (e) { console.log("Err:", e.message); }
}

async function run() {
    await probe('/sports/list'); // Check supported sports
    await probe('/news/list?category=cricket'); // Check if cricket news exists
    await probe('/matches/list?category=cricket'); // Guess
    await probe('/matches/v2/list-live?Category=cricket');
}

run();
