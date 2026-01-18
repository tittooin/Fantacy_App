const axios = require('axios');
const apiKey = '0f7ca5bd05msh3c4666a53a408e7p18a355jsnf0b0ef39619e';
const apiHost = 'cricbuzz-cricket2.p.rapidapi.com';

// Mock Input (From Match 137819)
const matchId = '137819';
const seriesId = '11176';
const t1Id = '96'; // Afghanistan
const t2Id = '10'; // West Indies

async function mockCloudflareLogic() {
    console.log("Mocking Cloudflare Function Logic...");

    try {
        // 1. Try scov2 (Live)
        console.log("1. Testing scov2...");
        try {
            const res1 = await axios.get(`https://${apiHost}/mcenter/v1/${matchId}/scov2`, {
                headers: { 'X-RapidAPI-Key': apiKey, 'X-RapidAPI-Host': apiHost }
            });
            if (res1.data.matchInfo && res1.data.matchInfo.team1 && res1.data.matchInfo.team1.playerDetails) {
                console.log("✅ Found in scov2 (Playing XI)");
                return;
            }
        } catch (e) {
            console.log("   scov2 failed (Expected if pre-match):", e.response?.status);
        }

        // 2. Fallback (Series Squads)
        console.log("2. Testing Series Squads Fallback...");
        if (seriesId && t1Id && t2Id) {
            // A. Get Series Squads List
            const res2 = await axios.get(`https://${apiHost}/series/v1/${seriesId}/squads`, {
                headers: { 'X-RapidAPI-Key': apiKey, 'X-RapidAPI-Host': apiHost }
            });
            const squads = res2.data.squads;
            console.log(`   Found ${squads.length} squads in series.`);

            let t1SquadId = null;
            let t2SquadId = null;

            for (const s of squads) {
                if (s.teamId == t1Id) t1SquadId = s.squadId;
                if (s.teamId == t2Id) t2SquadId = s.squadId;
            }

            console.log(`   T1 (96) SquadID: ${t1SquadId}`);
            console.log(`   T2 (10) SquadID: ${t2SquadId}`);

            if (!t1SquadId || !t2SquadId) {
                console.log("❌ Failed to resolve Squad IDs");
                return;
            }

            // B. Fetch Squad Details
            const fetchS = async (sid) => {
                const r = await axios.get(`https://${apiHost}/series/v1/${seriesId}/squads/${sid}`, {
                    headers: { 'X-RapidAPI-Key': apiKey, 'X-RapidAPI-Host': apiHost }
                });
                return r.data.player || [];
            };

            const [p1, p2] = await Promise.all([fetchS(t1SquadId), fetchS(t2SquadId)]);
            console.log(`✅ Success! Fetched T1: ${p1.length}, T2: ${p2.length}`);

        } else {
            console.log("❌ Missing IDs for Fallback");
        }

    } catch (err) {
        console.error("❌ Logic Error:", err.message);
    }
}

mockCloudflareLogic();
