const axios = require('axios');

async function probe() {
    const endpoints = [
        '/cricket-livescores',
        '/livescores',
        '/live-scores',
        '/cricket-live-scores'
    ];

    const headers = {
        'x-rapidapi-key': '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee',
        'x-rapidapi-host': 'free-cricbuzz-cricket-api.p.rapidapi.com'
    };

    console.log("Testing endpoints based on screenshot...");

    for (const ep of endpoints) {
        try {
            console.log(`Testing ${ep}...`);
            const response = await axios.get(`https://free-cricbuzz-cricket-api.p.rapidapi.com${ep}`, { headers });
            console.log(`✅ SUCCESS: ${ep}`);
            console.log(JSON.stringify(response.data, null, 2).substring(0, 1000));
            return;
        } catch (error) {
            console.error(`❌ FAILED ${ep}: ${error.response ? error.response.status : error.message}`);
        }
    }
}

probe();
