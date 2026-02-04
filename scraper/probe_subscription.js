
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';

// 1. The API you WERE using (Primary)
const HOST_CRICBUZZ = 'unofficial-cricbuzz.p.rapidapi.com';

// 2. The API from Screenshot
const HOST_LIVESCORE = 'livescore6.p.rapidapi.com';

async function probe(host, label) {
    console.log(`\n--- Probing ${label} (${host}) ---`);
    // Try a very basic endpoint
    let endpoint = '/matches/list';
    if (host.includes('cricbuzz')) endpoint = '/matches/list?matchState=live';
    if (host.includes('livescore')) endpoint = '/news/list?category=soccer'; // From screenshot

    const url = `https://${host}${endpoint}`;

    try {
        const resp = await fetch(url, { headers: { 'x-rapidapi-key': RAPID_API_KEY, 'x-rapidapi-host': host } });
        console.log(`Status: ${resp.status}`);

        const rem = resp.headers.get('x-ratelimit-requests-remaining');
        const quota = resp.headers.get('x-ratelimit-requests-limit');
        console.log(`Quota Remaining: ${rem} / ${quota}`);

        if (resp.ok) console.log("✅ API is ACTIVE and PAID.");
        else {
            const t = await resp.text();
            console.log("❌ Error:", t.substring(0, 200));
        }

    } catch (e) { console.log("Conn Error:", e.message); }
}

async function run() {
    await probe(HOST_CRICBUZZ, 'Unofficial Cricbuzz (Existing)');
    await probe(HOST_LIVESCORE, 'LiveScore6 (From Screenshot)');
}

run();
