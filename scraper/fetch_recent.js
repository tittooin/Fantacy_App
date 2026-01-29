const axios = require('axios');

async function fetchRecent() {
    const options = {
        method: 'GET',
        url: 'https://free-cricbuzz-cricket-api.p.rapidapi.com/cricket-schedule',
        params: { type: 'recent' },
        headers: {
            'x-rapidapi-key': '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee',
            'x-rapidapi-host': 'free-cricbuzz-cricket-api.p.rapidapi.com'
        }
    };

    try {
        console.log("Fetching recent schedule...");
        const response = await axios.request(options);
        console.log(JSON.stringify(response.data, null, 2).substring(0, 3000));
    } catch (error) {
        console.error(error);
    }
}

fetchRecent();
