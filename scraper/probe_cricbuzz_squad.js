
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const HOST = 'cricbuzz-cricket.p.rapidapi.com';
const MATCH_ID = 139029;

async function probe() {
    console.log(`🔍 Probing Cricbuzz Cricket (${HOST}) for Match ${MATCH_ID}...`);

    // 1. Get Match Info to find Series ID
    const infoUrl = `https://${HOST}/matches/v1/get-info?matchId=${MATCH_ID}`;
    console.log(`\n➡️ Testing Match Info: ${infoUrl}`);

    let seriesId = null;

    try {
        const r = await fetch(infoUrl, {
            headers: { 'x-rapidapi-key': RAPID_API_KEY, 'x-rapidapi-host': HOST }
        });

        if (r.ok) {
            const d = await r.json();
            if (d.matchInfo) {
                console.log("✅ Match Found:", d.matchInfo.seriesName, "vs", d.matchInfo.matchDesc);
                console.log("Series ID:", d.matchInfo.seriesId);
                seriesId = d.matchInfo.seriesId;
            } else {
                console.log("⚠️ No matchInfo in response.");
            }
        } else {
            console.log(`❌ Match Info Failed: ${r.status} ${r.statusText}`);
        }
    } catch (e) {
        console.error("Fetch Error:", e.message);
    }

    // 2. Test Squad Endpoint
    if (seriesId) {
        const squadUrl = `https://${HOST}/series/v1/${seriesId}/squads/${MATCH_ID}`;
        console.log(`\n🔎 Testing Squad Endpoint: ${squadUrl}`);

        try {
            const r = await fetch(squadUrl, {
                headers: { 'x-rapidapi-key': RAPID_API_KEY, 'x-rapidapi-host': HOST }
            });

            if (r.ok) {
                const d = await r.json();
                if (d.items && d.items.length > 0) {
                    console.log(`✅ SQUAD DATA FOUND! Teams: ${d.items.length}`);
                    d.items.forEach(t => console.log(`- ${t.teamName}: ${t.players.length} players`));
                } else {
                    console.log("⚠️ Squad response ok but empty items/players.");
                }
            } else {
                console.log(`❌ Squad Fetch Failed: ${r.status}`);
            }
        } catch (e) {
            console.error("Squad Error:", e.message);
        }
    }
}

probe();
