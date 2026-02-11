const https = require('https');

const url = 'https://fantasy-cricket-api.moremagical4.workers.dev/api/scorecard?matchId=106700';

https.get(url, (res) => {
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
        try {
            const json = JSON.parse(data);
            console.log("Raw Response:");
            // console.log(JSON.stringify(json, null, 2));

            if (json.scorecard && json.scorecard.score_details) {
                const details = JSON.parse(json.scorecard.score_details);
                console.log("\nDecoded Score Details:");
                console.log(JSON.stringify(details, null, 2));
            }
        } catch (e) {
            console.error(e);
        }
    });
}).on('error', (err) => {
    console.error("Error: " + err.message);
});
