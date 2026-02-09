
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const HOST = 'cricbuzz-cricket.p.rapidapi.com';
const SERIES_ID = 11253;

async function probe() {
    console.log(`🔍 Probing Series Squads for Series ${SERIES_ID}...`);

    const url = `https://${HOST}/series/v1/${SERIES_ID}/squads`;
    console.log(`\n🔎 Testing: ${url}`);

    try {
        const r = await fetch(url, {
            headers: { 'x-rapidapi-key': RAPID_API_KEY, 'x-rapidapi-host': HOST }
        });

        console.log(`Status: ${r.status}`);

        if (r.ok) {
            const d = await r.json();
            console.log("Keys:", Object.keys(d));

            if (d.squads && d.squads.length > 0) {
                console.log(`✅ SERIES SQUADS FOUND! Count: ${d.squads.length}`);
                d.squads.slice(0, 3).forEach(s => console.log(`- ${s.squadType} (ID: ${s.squadId})`));
            } else {
                console.log("⚠️ Response ok but 'squads' empty.");
            }
        } else {
            console.log(`❌ Fetch Failed: ${r.status}`);
        }
    } catch (e) {
        console.error("Error:", e.message);
    }
}

probe();
