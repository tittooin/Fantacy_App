const https = require('https');

const apiKey = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const apiHost = 'cricbuzz-cricket.p.rapidapi.com';
const seriesId = 7688; // Example Series
const playerId = 14254; // Example Player (Virat Kohli)

async function fetchAPI(path) {
    const options = {
        method: 'GET',
        hostname: apiHost,
        port: null,
        path: path,
        headers: {
            'x-rapidapi-key': apiKey,
            'x-rapidapi-host': apiHost,
            'useQueryString': true
        }
    };

    return new Promise((resolve, reject) => {
        const req = https.request(options, function (res) {
            const chunks = [];
            res.on('data', function (chunk) {
                chunks.push(chunk);
            });
            res.on('end', function () {
                const body = Buffer.concat(chunks);
                try {
                    resolve(JSON.parse(body.toString()));
                } catch (e) {
                    resolve({ error: "Parse Error", body: body.toString() });
                }
            });
        });
        req.on('error', reject);
        req.end();
    });
}

async function probe() {
    console.log("🔍 Probing Stats Endpoints...");

    // 1. Series Stats (Best Case - Bulk)
    console.log("1. Checking Series Stats...");
    const statsPaths = [
        `/stats/v1/series/${seriesId}`,
        `/series/v1/${seriesId}/stats`,
        `/stats/v1/rankings/batsmen`,
    ];

    for (const p of statsPaths) {
        console.log(`   GET ${p}`);
        const data = await fetchAPI(p);
        if (data && !data.message && !data.error) {
            console.log(`   ✅ SUCCESS: Found Data at ${p}`);
            console.log(JSON.stringify(data, null, 2).slice(0, 200));
        } else {
            console.log(`   ❌ FAILED: ${data.message || 'No Data'}`);
        }
    }

    // 2. Individual Player Stats (Fallback)
    console.log("\n2. Checking Individual Player Stats...");
    const playerPaths = [
        `/stats/v1/player/${playerId}`,
        `/players/v1/${playerId}/stats`,
        `/stats/v1/player/${playerId}/career` // Common pattern
    ];

    for (const p of playerPaths) {
        console.log(`   GET ${p}`);
        const data = await fetchAPI(p);
        if (data && !data.message) {
            console.log(`   ✅ SUCCESS: Found Data at ${p}`);
            // Log useful stats keys
            const keys = Object.keys(data);
            console.log(`   Keys: ${keys.join(', ')}`);
        } else {
            console.log(`   ❌ FAILED: ${data.message || 'No Data'}`);
        }
    }
}

probe();
