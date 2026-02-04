
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const HOST = 'livescore6.p.rapidapi.com';

async function auditLineups() {
    const eid = '1637155'; // Sri Lanka vs England
    const url = `https://${HOST}/matches/v2/get-lineups?Eid=${eid}&Category=cricket`;
    console.log(`Fetching Lineups: ${url}`);

    try {
        const resp = await fetch(url, { headers: { 'x-rapidapi-key': RAPID_API_KEY, 'x-rapidapi-host': HOST } });
        if (resp.ok) {
            const data = await resp.json();

            // Log Top Level Keys
            console.log("Keys:", Object.keys(data));

            // Inspect 'Lu' (Lineups)
            const lu = data.Lu || [];
            if (lu.length > 0) {
                console.log(`\n--- Lineups Data (${lu.length} Teams) ---`);

                lu.forEach((teamLu, index) => {
                    console.log(`\nTeam ${index + 1} Raw:`, JSON.stringify(teamLu, null, 2).substring(0, 200));

                    // Look for Players
                    const players = teamLu.Ps || teamLu.Players || [];
                    if (players.length > 0) {
                        console.log(`Found ${players.length} Players. Sample:`);
                        console.log(JSON.stringify(players[0], null, 2));
                    }
                });
            } else {
                console.log("Lineups array is empty.");
            }

        }
    } catch (e) { console.error("Error:", e.message); }
}

auditLineups();
