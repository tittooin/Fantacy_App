const fs = require('fs');
const path = require('path');

const BASE_URL = 'https://fantasy-cricket-api.moremagical4.workers.dev';
const ARTIFACTS_DIR = process.argv[2];

async function generateProofs() {
    console.log("🚀 Generating Proofs for AxevoraLabs...");

    const endpoints = [
        { name: 'matches', url: `${BASE_URL}/matches` },
        { name: 'scorecard', url: `${BASE_URL}/scorecard?matchId=89675` }, // Example ID
        { name: 'room_leaderboard', url: `${BASE_URL}/api/room/leaderboard?matchId=89675` }
    ];

    for (const ep of endpoints) {
        try {
            console.log(`📡 Fetching ${ep.name}...`);
            const res = await fetch(ep.url);
            const data = await res.json();
            const timestamp = new Date().toISOString();
            const filename = `proof_${ep.name}_${Date.now()}.json`;
            const filepath = path.join(ARTIFACTS_DIR, filename);

            fs.writeFileSync(filepath, JSON.stringify({
                endpoint: ep.url,
                timestamp,
                response: data
            }, null, 2));
            console.log(`✅ Saved ${filename}`);
        } catch (e) {
            console.error(`❌ Failed ${ep.name}: ${e.message}`);
        }
    }
}

generateProofs();
