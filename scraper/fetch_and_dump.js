const axios = require('axios');
const fs = require('fs');

async function fetchAndDump() {
    const options = {
        method: 'GET',
        url: 'https://free-cricbuzz-cricket-api.p.rapidapi.com/cricket-schedule',
        params: { type: 'all' }, // Fetch all types to be sure
        headers: {
            'x-rapidapi-key': '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee',
            'x-rapidapi-host': 'free-cricbuzz-cricket-api.p.rapidapi.com'
        }
    };

    try {
        console.log("Fetching schedule...");
        const response = await axios.request(options);
        const dumpData = JSON.stringify(response.data, null, 2);
        fs.writeFileSync('scraper/full_match_dump.json', dumpData);
        console.log("Dumped schedule data to scraper/full_match_dump.json");
    } catch (error) {
        console.error(error);
    }
}

fetchAndDump();
