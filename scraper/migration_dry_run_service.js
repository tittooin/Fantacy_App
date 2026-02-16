
const https = require('https');

// CONFIG
const API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const API_HOST = 'cricbuzz-cricket.p.rapidapi.com';

// MOCK ENV directly in script
const env = {
    RAPID_API_KEY: API_KEY
};

async function fetchAPI(path) {
    return new Promise((resolve) => {
        const options = {
            method: 'GET',
            hostname: API_HOST,
            path: path,
            headers: {
                'x-rapidapi-key': API_KEY,
                'x-rapidapi-host': API_HOST,
                'User-Agent': 'AxevoraDryRun/1.0'
            }
        };
        const req = https.request(options, (res) => {
            let chunks = [];
            res.on('data', d => chunks.push(d));
            res.on('end', () => {
                if (res.statusCode === 204) { resolve(null); return; }
                try { resolve(JSON.parse(Buffer.concat(chunks).toString())); }
                catch (e) { resolve(null); }
            });
        });
        req.on('error', () => resolve(null));
        req.end();
    });
}

async function runServiceDryRun() {
    console.log("🛠️ STARTING MIGRATION DRY RUN (SAFE MODE: NO DB WRITES)\n");

    // 1. Fetch Matches (Upcoming)
    console.log("1️⃣  Fetching Upcoming Matches...");
    const upcoming = await fetchAPI('/matches/v1/upcoming');

    let matchesToCheck = [];
    if (upcoming && upcoming.typeMatches) {
        // Flatten
        upcoming.typeMatches.forEach(tm => {
            if (tm.seriesMatches) {
                tm.seriesMatches.forEach(sm => {
                    if (sm.seriesAdWrapper && sm.seriesAdWrapper.matches) {
                        matchesToCheck.push(...sm.seriesAdWrapper.matches.map(m => m.matchInfo));
                    }
                });
            }
        });
    }

    console.log(`    Found ${matchesToCheck.length} Upcoming Matches.`);

    // Pick 3 samples (including 139216 if present)
    const targetId = 139216;
    let samples = matchesToCheck.filter(m => m.matchId == targetId);
    if (samples.length === 0) samples.push(matchesToCheck[0]);
    if (matchesToCheck.length > 1) samples.push(matchesToCheck[1]);

    // Dedupe
    samples = [...new Set(samples)].slice(0, 3);

    console.log(`\n2️⃣  Processing ${samples.length} Sample Matches for SQUAD FETCH:\n`);

    for (const match of samples) {
        if (!match) continue;
        console.log(`   🏏 MATCH: ${match.matchId} | ${match.team1?.teamName} vs ${match.team2?.teamName}`);
        console.log(`      Series ID: ${match.seriesId}`);
        console.log(`      Status: ${match.state}`);

        // FETCH SQUADS Logic (Simulated Adapter)
        if (match.seriesId) {
            const sUrl = `/series/v1/${match.seriesId}/squads`;
            console.log(`      📡 Fetching Series Squads: ${sUrl}`);
            const sData = await fetchAPI(sUrl);

            if (sData && sData.squads) {
                const squadCount = sData.squads.length;
                console.log(`      ✅ Squad Data Received: ${squadCount} items`);

                // Try to match teams
                const t1Name = match.team1?.teamName || '';
                const t2Name = match.team2?.teamName || '';

                const t1Squad = sData.squads.find(s => !s.isHeader && (s.squadType === t1Name || (s.teamName && s.teamName.includes(t1Name))));
                const t2Squad = sData.squads.find(s => !s.isHeader && (s.squadType === t2Name || (s.teamName && s.teamName.includes(t2Name))));

                if (t1Squad) {
                    console.log(`         Example Player (Team 1 - ${t1Name}):`);
                    // Helper to fetch players if squads returns ID or full list
                    // Cricbuzz series squads usually returns the list directly? Or ID?
                    // Probe returned "squadType", "isHeader". 
                    // I need to print a non-header item to know if I need another fetch.
                    const nonHeader = sData.squads.find(s => !s.isHeader);
                    if (nonHeader) {
                        if (nonHeader.squadId) {
                            console.log(`         Squad ID found: ${nonHeader.squadId}. Needs deeper fetch.`);
                            const pUrl = `/series/v1/${match.seriesId}/squads/${nonHeader.squadId}`;
                            const pData = await fetchAPI(pUrl);
                            if (pData && pData.player) {
                                console.log(`         ✅ Players Fetched: ${pData.player.length} players`);
                                console.log(`            [1] ${pData.player[0].name} (${pData.player[0].role})`);
                            }
                        } else {
                            console.log(`         Structure Unknown: ${JSON.stringify(nonHeader).substring(0, 100)}...`);
                        }
                    }
                } else {
                    console.log("         ⚠️ Could not auto-match Team Names to Squad list.");
                    // Dump squad names
                    const names = sData.squads.map(s => s.squadType || s.teamName).filter(x => x);
                    console.log(`         Available Squads: ${names.join(', ')}`);
                }

            } else {
                console.log("      ❌ No squads found in Series endpoint.");
            }
        }
        console.log("-".repeat(50));
    }

    console.log("\n✅ DRY RUN COMPLETE. NO DATA SAVED.");
}

runServiceDryRun();
