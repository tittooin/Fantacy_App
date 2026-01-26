const axios = require('axios');

async function probe() {
    const matchId = '124832'; // Tripura vs Uttarakhand, likely active
    const endpoints = [
        '/mcenter.v1.json',
        '/match-center',
        '/cricket-scorecard',
        '/scorecard',
        '/matches/scorecard',
        '/cricket-match-scorecard',
        '/cricket-live-match-score',
        '/match-score',
        '/match-info',
        '/get-scorecard',
        '/matches/get-scorecard'
    ];

    const headers = {
        'x-rapidapi-key': '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee',
        'x-rapidapi-host': 'free-cricbuzz-cricket-api.p.rapidapi.com'
    };

    for (const ep of endpoints) {
        // Test 1: Query Param
        try {
            console.log(`Testing Query: ${ep}?matchId=${matchId}`);
            const res = await axios.get(`https://free-cricbuzz-cricket-api.p.rapidapi.com${ep}`, {
                params: { matchId }, headers
            });
            console.log(`✅ SUCCESS (Query): ${ep}`);
            return;
        } catch (e) { process.stdout.write('.'); }

        // Test 2: Path Param (no extension)
        try {
            const url = `https://free-cricbuzz-cricket-api.p.rapidapi.com${ep}/${matchId}`;
            console.log(`Testing Path: ${url}`);
            const res = await axios.get(url, { headers });
            console.log(`✅ SUCCESS (Path): ${ep}`);
            return;
        } catch (e) { process.stdout.write('.'); }
    }
    console.log("\nAll probes failed.");
}

probe();
