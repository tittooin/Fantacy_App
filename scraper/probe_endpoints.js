const axios = require('axios');

async function probe() {
    const matchId = '141903'; // Likely valid ID
    const endpoints = [
        '/mcenter.v1.json',
        '/match-center',
        '/cricket-scorecard',
        '/scorecard',
        '/matches/scorecard'
    ];

    const headers = {
        'x-rapidapi-key': '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee',
        'x-rapidapi-host': 'free-cricbuzz-cricket-api.p.rapidapi.com'
    };

    for (const ep of endpoints) {
        try {
            console.log(`Testing ${ep}...`);
            const response = await axios.get(`https://free-cricbuzz-cricket-api.p.rapidapi.com${ep}`, {
                params: { matchId },
                headers
            });
            console.log(`✅ SUCCESS: ${ep}`);
            console.log(JSON.stringify(response.data, null, 2).substring(0, 500)); // Show sneak peek
            return; // Stop on first success
        } catch (error) {
            console.error(`❌ FAILED ${ep}: ${error.response ? error.response.status : error.message}`);
        }
    }
}

probe();
