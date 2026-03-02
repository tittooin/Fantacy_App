const axios = require('axios');

async function debugHTML() {
    const { data } = await axios.get('https://www.cricbuzz.com/cricket-match/live-scores', {
        headers: { 'User-Agent': 'Mozilla/5.0' }
    });
    const matchId = '139450'; // Zimbabwe vs South Africa
    const index = data.indexOf(matchId);
    if (index > -1) {
        console.log(data.substring(index - 200, index + 2000));
    } else {
        console.log("Match ID not found in HTML!");
    }
}
debugHTML();
