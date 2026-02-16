const axios = require('axios');

// MATCHED LOGIC FROM squad_engine.js
async function checkMatch(matchId) {
    try {
        console.log(`Checking ${matchId}...`);

        // 1. Get Match Info from FREE API (like squad_engine)
        // squad_engine uses: https://cricbuzz-cricket.p.rapidapi.com/mcenter/v1/${matchId} (Official)
        // AND https://free-cricbuzz-cricket-api.p.rapidapi.com/matches/v1/${matchId} (Free backup)

        // Let's try the Official one which squad_engine tries first
        const infoRes = await axios.get(`https://cricbuzz-cricket.p.rapidapi.com/mcenter/v1/${matchId}`, {
            headers: {
                'x-rapidapi-key': '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee',
                'x-rapidapi-host': 'cricbuzz-cricket.p.rapidapi.com'
            },
            validateStatus: false
        });

        let t1Id, t2Id, t1Name, t2Name;

        if (infoRes.status === 200 && infoRes.data.matchInfo) {
            t1Id = infoRes.data.matchInfo.team1.id;
            t2Id = infoRes.data.matchInfo.team2.id;
            t1Name = infoRes.data.matchInfo.team1.teamName;
            t2Name = infoRes.data.matchInfo.team2.teamName;
        } else {
            // Fallback to Free API
            const freeRes = await axios.get(`https://free-cricbuzz-cricket-api.p.rapidapi.com/matches/v1/${matchId}`, {
                headers: {
                    'x-rapidapi-key': '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee',
                    'x-rapidapi-host': 'free-cricbuzz-cricket-api.p.rapidapi.com'
                },
                validateStatus: false
            });
            if (freeRes.data && freeRes.data.matchInfo) {
                t1Id = freeRes.data.matchInfo.team1.teamId;
                t2Id = freeRes.data.matchInfo.team2.teamId;
                t1Name = freeRes.data.matchInfo.team1.teamName;
                t2Name = freeRes.data.matchInfo.team2.teamName;
            }
        }

        if (!t1Id) {
            console.log(`❌ Match ${matchId} info not found`);
            return false;
        }
        console.log(`👉 ${t1Name} (${t1Id}) vs ${t2Name} (${t2Id})`);

        // 2. Fetch Squad
        // squad_engine uses `free-cricbuzz-cricket-api` -> /cricket-team-squad
        const sqRes = await axios.get(`https://free-cricbuzz-cricket-api.p.rapidapi.com/cricket-team-squad`, {
            params: { teamId: t1Id },
            headers: {
                'x-rapidapi-key': '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee',
                'x-rapidapi-host': 'free-cricbuzz-cricket-api.p.rapidapi.com'
            },
            validateStatus: false
        });

        if (sqRes.status === 200 && sqRes.data.players && sqRes.data.players.length > 0) {
            console.log(`✅ VALID SQUAD FOUND for ${matchId} (Team ${t1Id} has ${sqRes.data.players.length} players)`);
            return true;
        } else {
            console.log(`❌ No squad for Team ${t1Id} (Status: ${sqRes.status})`);
        }

    } catch (e) {
        console.log(`Error: ${e.message}`);
    }
    return false;
}

// Hardcoded recent match IDs from fetch_recent (future & past)
// 124920 (IRE vs ZIM)
// 132142 (ND vs WEL)
// Let's try to verify if ANY works.
const candidates = ['132142', '132131', '132120', '124920', '101648', '95066'];

async function run() {
    for (const id of candidates) {
        if (await checkMatch(id)) break;
    }
}
run();
