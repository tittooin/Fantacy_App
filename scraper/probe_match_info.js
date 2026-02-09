
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const HOST = 'livescore6.p.rapidapi.com';
const MATCH_ID = 139029;

async function probe() {
    console.log(`🔍 Probing Match Info for ${MATCH_ID}...`);

    // 1. Get Match Detail (to find Series ID)
    // Common endpoints for LiveScore6 / Cricbuzz-like APIs
    const paths = [
        `/matches/v2/get-info?matchId=${MATCH_ID}`,
        `/matches/v2/detail?matchId=${MATCH_ID}`,
        `/matches/v1/get-info?matchId=${MATCH_ID}`
    ];

    let seriesId = null;

    for (const p of paths) {
        const url = `https://${HOST}${p}`;
        console.log(`\n➡️ Testing: ${url}`);
        try {
            const r = await fetch(url, {
                headers: {
                    'x-rapidapi-key': RAPID_API_KEY,
                    'x-rapidapi-host': HOST
                }
            });
            console.log(`Status: ${r.status}`);
            if (r.ok) {
                const d = await r.json();
                console.log("Response Keys:", Object.keys(d));

                // Try to find Series ID
                // Structure varies, usually d.matchInfo.seriesId or d.seriesId
                if (d.matchInfo) {
                    console.log("Found matchInfo:", d.matchInfo.seriesName, "ID:", d.matchInfo.seriesId);
                    seriesId = d.matchInfo.seriesId;
                } else if (d.seriesId) {
                    seriesId = d.seriesId;
                }

                if (seriesId) break;
            } else {
                console.log("Body:", await r.text());
            }
        } catch (e) {
            console.error("Error:", e.message);
        }
    }

    if (seriesId) {
        console.log(`\n✅ FOUND SERIES ID: ${seriesId}`);

        // 2. Now Test Squad Endpoint with this Series ID
        const squadUrl = `https://${HOST}/series/v1/${seriesId}/squads/${MATCH_ID}`;
        console.log(`\n🔎 Testing Squad Endpoint: ${squadUrl}`);

        try {
            const r = await fetch(squadUrl, {
                headers: {
                    'x-rapidapi-key': RAPID_API_KEY,
                    'x-rapidapi-host': HOST
                }
            });
            console.log(`Status: ${r.status}`);
            if (r.ok) {
                const d = await r.json();
                console.log("Squad Data Keys:", Object.keys(d));
                if (d.items) {
                    console.log("Items Count:", d.items.length);
                    d.items.forEach((team, i) => {
                        console.log(`Team ${i + 1}: ${team.teamName} - Players: ${team.players ? team.players.length : 0}`);
                    });
                }
            } else {
                // 204 often means empty
                if (r.status === 204) console.log("⚠️ 204 No Content (Empty Squad)");
            }
        } catch (e) {
            console.error("Squad Error:", e.message);
        }

    } else {
        console.log("❌ Could not find Series ID.");
    }

}

probe();
