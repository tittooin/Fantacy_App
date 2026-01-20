const axios = require('axios');
const API_KEY = "0f7ca5bd05msh3c4666a53a408e7p18a355jsnf0b0ef39619e"; // From diag_key.js
const SERIES_ID = 10394; // Paarl vs Joburg

async function run() {
    try {
        const headers = {
            'X-RapidAPI-Key': API_KEY,
            'X-RapidAPI-Host': 'cricbuzz-cricket2.p.rapidapi.com'
        };

        // 2. Get Series Squads Map
        console.log(`Fetching Squads Map for Series ${SERIES_ID}...`);
        const sRes = await axios.get(`https://cricbuzz-cricket2.p.rapidapi.com/series/v1/${SERIES_ID}/squads`, { headers });
        const squads = sRes.data.squads;

        let firstSquadId = null;
        if (squads && squads.length > 0) {
            console.log(`Found ${squads.length} squads.`);

            for (const s of squads) {
                if (s.isHeader) continue;
                console.log("Valid Squad:", JSON.stringify(s, null, 2));
                if (!firstSquadId) firstSquadId = s.squadId;
            }

            if (!firstSquadId) {
                console.log("No non-header squads found.");
                return;
            }

            // 3. Fetch Actual Squad logic
            console.log(`\nInspecting Squad ID: ${firstSquadId}`);

            // 3. Fetch Actual Squad logic
            console.log(`Fetching Squad Details ${firstSquadId}...`);
            const sqRes = await axios.get(`https://cricbuzz-cricket2.p.rapidapi.com/series/v1/${SERIES_ID}/squads/${firstSquadId}`, { headers });
            const players = sqRes.data.player;
            if (players && players.length > 0) {
                console.log("Found Players! Sample:");
                // Print first player fully
                console.log(JSON.stringify(players[0], null, 2));

                // Check roles
                players.forEach(p => {
                    // Print Name and Role
                    console.log(`  ${p.name}: Role="${p.role}"`);
                });
            } else {
                console.log("No players in squad response.");
            }
        } else {
            console.log("No squads found for series.");
        }

    } catch (e) {
        console.error(e.message);
        if (e.response) console.error(e.response.data);
    }
}

run();
