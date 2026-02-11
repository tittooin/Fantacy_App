const https = require('https');

const url = 'https://fantasy-cricket-api.moremagical4.workers.dev/api/scorecard?matchId=106700';

https.get(url, (res) => {
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
        try {
            const json = JSON.parse(data);
            if (json.scorecard && json.scorecard.score_details) {
                const details = JSON.parse(json.scorecard.score_details);
                if (details.innings && details.innings.length > 0) {
                    console.log("Inning 1 Keys:", Object.keys(details.innings[0]));
                    // Check if 'bowlcard' or similar exists
                }
            }
        } catch (e) {
            console.error(e);
        }
    });
});
