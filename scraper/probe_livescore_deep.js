
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
            const txt = JSON.stringify(json).substring(0, 400);
            console.log("Response:", txt);
        } else {
            console.log("Fail:", resp.status);
        }
    } catch (e) { console.log("Err:", e.message); }
}

async function run() {
    // 1. Try to find the Category ID for Cricket
    // Some LiveScore APIs use 'matches/v2/list-by-league?Category=cricket'
    // Some use 'news/v2/list?category=cricket'
    await probe('/matches/v2/list-live?Category=cricket');
    await probe('/matches/v2/list-by-date?Category=cricket&Date=20240203');

    // 2. Try 'meta' endpoints
    await probe('/meta/sports');
    await probe('/categories/list');

    // 3. Try lower case
    await probe('/matches/v2/list-live?category=cricket');
}

run();
