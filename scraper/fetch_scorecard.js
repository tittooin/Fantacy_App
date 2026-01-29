const axios = require('axios');
const fs = require('fs');

async function fetchScorecard() {
    const options = {
        method: 'GET',
        url: 'https://free-cricbuzz-cricket-api.p.rapidapi.com/scorecard',
        params: { matchId: '107297' }, // Using a likely valid match ID (or I can pick one from recent logs if this fails)
        headers: {
            'x-rapidapi-key': '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee',
            'x-rapidapi-host': 'free-cricbuzz-cricket-api.p.rapidapi.com'
        }
    };

    try {
        const response = await axios.request(options);
        console.log(JSON.stringify(response.data, null, 2));
    } catch (error) {
        console.error(error);
    }
}

fetchScorecard();
