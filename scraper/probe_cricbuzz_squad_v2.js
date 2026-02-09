
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const HOST = 'cricbuzz-cricket.p.rapidapi.com';
const MATCH_ID = 139029;
const SERIES_ID = 11253;

async function probe() {
    console.log(`🔍 Probing Squad for Match ${MATCH_ID} (Series ${SERIES_ID})...`);

    // Direct Squad Endpoint
    const squadUrl = `https://${HOST}/series/v1/${SERIES_ID}/squads/${MATCH_ID}`;
    console.log(`\n🔎 Testing Squad Endpoint: ${squadUrl}`);

    try {
        const r = await fetch(squadUrl, {
            headers: { 'x-rapidapi-key': RAPID_API_KEY, 'x-rapidapi-host': HOST }
        });

        console.log(`Status: ${r.status}`);

        if (r.ok) {
            // Check for 204
            if (r.status === 204) {
                console.log("⚠️ 204 No Content (Empty).");
                return;
            }

            const d = await r.json();
            console.log("Response Keys:", Object.keys(d));

            if (d.items && d.items.length > 0) {
                console.log(`✅ SQUAD DATA FOUND! Teams: ${d.items.length}`);
                d.items.forEach(t => console.log(`- ${t.teamName}: ${t.players.length} players`));
            } else {
                console.log("⚠️ Squad response ok but empty items/players.");
            }
        } else {
            console.log(`❌ Squad Fetch Failed: ${r.status} ${r.statusText}`);
            console.log("Body:", await r.text());
        }
    } catch (e) {
        console.error("Squad Error:", e.message);
    }
}

probe();
