
const https = require('https');

const API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const API_HOST = 'cricbuzz-cricket.p.rapidapi.com';

function fetchAPI(path) {
    return new Promise((resolve, reject) => {
        const options = {
            method: 'GET',
            hostname: API_HOST,
            path: path,
            headers: {
                'x-rapidapi-key': API_KEY,
                'x-rapidapi-host': API_HOST,
                'User-Agent': 'AxevoraProbe/1.0'
            }
        };

        const req = https.request(options, (res) => {
            let chunks = [];
            res.on('data', (d) => chunks.push(d));
            res.on('end', () => {
                const body = Buffer.concat(chunks).toString();
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    try {
                        resolve(JSON.parse(body));
                    } catch (e) {
                        console.error("JSON Parse Error:", e);
                        resolve({}); // Fail safe
                    }
                } else {
                    console.error(`❌ API Error [${res.statusCode}] for ${path}`);
                    resolve(null);
                }
            });
        });

        req.on('error', (e) => reject(e));
        req.end();
    });
}

async function runDryRun() {
    console.log("🚀 STARTING DRY RUN: Cricbuzz API");

    // 1. Fetch Live Matches
    console.log("\n📡 Fetching Live Matches...");
    const liveData = await fetchAPI('/matches/v1/live');
    if (liveData) {
        console.log(`✅ Live Response Types: ${Object.keys(liveData)}`);
        // Cricbuzz usually has typeMatches header
        if (liveData.typeMatches) {
            console.log(`   Found ${liveData.typeMatches.length} match types.`);
            const firstMatch = liveData.typeMatches[0]?.seriesMatches[0]?.seriesAdWrapper?.matches[0]?.matchInfo;
            if (firstMatch) {
                console.log("   📝 Live Match Sample:");
                console.log(`   ID: ${firstMatch.matchId}`);
                console.log(`   Title: ${firstMatch.seriesName} - ${firstMatch.matchDesc}`);
                console.log(`   Status: ${firstMatch.state}`);
                console.log(`   Teams: ${firstMatch.team1?.teamName} vs ${firstMatch.team2?.teamName}`);
            }
        }
    }

    // 2. Fetch Upcoming Matches
    console.log("\n📡 Fetching Upcoming Matches...");
    const upcomingData = await fetchAPI('/matches/v1/upcoming');
    if (upcomingData && upcomingData.typeMatches) {
        console.log(`✅ Upcoming Data Found. Sample Match:`);
        const firstUp = upcomingData.typeMatches[0]?.seriesMatches[0]?.seriesAdWrapper?.matches[0]?.matchInfo;
        if (firstUp) {
            console.log(`   ID: ${firstUp.matchId}`);
            console.log(`   Start: ${new Date(parseInt(firstUp.startDate)).toISOString()}`);
        }
    }

    // 3. Squads / Scorecard Deep Dive
    const probeId = '139205'; // Live Match (likely has data)
    console.log(`\n🔍 Deep Probing Match ID: ${probeId}`);

    // Try dedicated SQUADS endpoint logic (often under matches)
    const formats = [
        `/matches/v1/${probeId}/squads`,
        `/mcenter/v1/${probeId}/squads`,
        `/mcenter/v1/${probeId}/team`
    ];

    for (const fmt of formats) {
        console.log(`   Trying ${fmt}...`);
        const data = await fetchAPI(fmt);
        if (data && (data.players || data.squads || data.team1)) {
            console.log(`   ✅ HIT! Found data at ${fmt}`);
            console.log(`   Keys: ${Object.keys(data)}`);
            if (data.players) console.log(`   Players Count: ${data.players.length}`);
        }
    }

    // 3. Series Squad Probe
    let seriesId = '0';
    let matchId = '139216'; // Upcoming match

    if (upcomingData && upcomingData.typeMatches) {
        const m = upcomingData.typeMatches[0]?.seriesMatches[0]?.seriesAdWrapper?.matches[0]?.matchInfo;
        if (m) {
            console.log(`\n🔍 Found Upcoming Match info for ${m.matchId}`);
            matchId = m.matchId;
            seriesId = m.seriesId;
            console.log(`   Series ID: ${seriesId}`);
        }
    }

    if (seriesId !== '0') {
        console.log(`\n🔍 Probing Series Squads for Series ${seriesId}...`);
        // Try /series/v1/{id}/squads
        const sUrl = `/series/v1/${seriesId}/squads`;
        const sData = await fetchAPI(sUrl);

        if (sData) {
            console.log(`   ✅ Series Squad Response Received`);
            console.log(`   Keys: ${Object.keys(sData)}`);
            if (sData.squads) {
                console.log(`   Squads Count: ${sData.squads.length}`);
                console.log(`   Sample Squad: ${JSON.stringify(sData.squads[0])}`);
            }
        }

        // Try Match Squad via Series
        // /series/v1/{seriesId}/squads/{matchId} ??
        const smUrl = `/series/v1/${seriesId}/squads/${matchId}`;
        const smData = await fetchAPI(smUrl);
        if (smData) {
            console.log(`   ✅ Match Specific Squad (via Series) Received`);
            // Usually returns { items: [...] } or { players: ... }
            console.log(`   Keys: ${Object.keys(smData)}`);
        }
    }

    // Inspect Scorecard for Players
    console.log(`\n   Checking Scorecard Structure...`);
    const scard = await fetchAPI(`/mcenter/v1/${probeId}/scard`);
    // API keys seem to be lowercase based on previous log: scorecard, ismatchcomplete
    if (scard && scard.scorecard && scard.scorecard[0]) {
        const sc = scard.scorecard[0]; // Is it an array? Cricbuzz often returns array for some endpoints
        console.log("   ✅ Found 'scorecard' key");

        // Deep dump of one team to find players
        if (sc.batteam) {
            console.log("   BatTeam Keys: ", Object.keys(sc.batteam));
        }
    } else {
        console.log("   Scorecard probe failed or structure unknown.");
    }

    console.log("\n🏁 DEEP PROBE COMPLETE");
}

runDryRun();
