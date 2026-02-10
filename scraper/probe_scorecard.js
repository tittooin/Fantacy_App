const axios = require('axios');

async function probeScorecard() {
    const matchId = 124920; // Known completed match
    const apiKey = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
    const apiHost = 'cricbuzz-cricket.p.rapidapi.com';

    const endpoints = [
        `/mcenter/v1/${matchId}/scard`,
        `/mcenter/v1/${matchId}/scorecard`,
        `/matches/v1/${matchId}/scorecard`,
        `/matches/v1/${matchId}/scard`
    ];

    const headers = {
        'x-rapidapi-key': apiKey,
        'x-rapidapi-host': apiHost
    };

    for (const ep of endpoints) {
        try {
            console.log(`Testing ${ep}...`);
            const url = `https://${apiHost}${ep}`;
            const response = await axios.get(url, { headers });

            console.log(`✅ SUCCESS: ${ep}`);
            console.log(JSON.stringify(response.data, null, 2).substring(0, 1000));
            return; // Stop on first success
        } catch (error) {
            console.log(`❌ FAILED ${ep}: ${error.response ? error.response.status : error.message}`);
        }
    }
}

probeScorecard();
