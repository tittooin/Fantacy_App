const fs = require('fs');

async function probeSquadStats() {
    const apiKey = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
    const apiHost = 'cricbuzz-cricket.p.rapidapi.com';
    const seriesId = 7688; // Use a known series
    const squadId = 84832; // Use a known squad ID (if available, otherwise we fetch series squads first)

    // 1. Fetch Series Squads to get a valid Squad ID
    const squadsUrl = `https://${apiHost}/series/v1/${seriesId}/squads`;
    console.log(`Fetching Squads from: ${squadsUrl}`);

    try {
        const resp = await fetch(squadsUrl, {
            headers: { 'x-rapidapi-key': apiKey, 'x-rapidapi-host': apiHost }
        });
        const data = await resp.json();

        if (!data.squads || data.squads.length === 0) {
            console.log("No squads found.");
            return;
        }

        const validSquad = data.squads.find(s => s.squadId);
        if (!validSquad) {
            console.log("No valid squad ID found.");
            return;
        }

        console.log(`Probing Squad ID: ${validSquad.squadId} (${validSquad.squadType})`);

        // 2. Fetch Players
        const playersUrl = `https://${apiHost}/series/v1/${seriesId}/squads/${validSquad.squadId}`;
        const pResp = await fetch(playersUrl, {
            headers: { 'x-rapidapi-key': apiKey, 'x-rapidapi-host': apiHost }
        });
        const pData = await pResp.json();

        if (pData.player && pData.player.length > 0) {
            console.log("___ PLAYER SAMPLE ___");
            console.log(JSON.stringify(pData.player[0], null, 2));

            // Check for stats inside specific player object if structure is complex
            // Sometimes it's nested or needing a separate 'stats' map
        } else {
            console.log("No players in squad.");
        }

    } catch (e) {
        console.error("Error:", e);
    }
}

probeSquadStats();
