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
                    const bat = details.innings[0].batsman ? details.innings[0].batsman[0] :
                        (details.innings[0].scorecard ? details.innings[0].scorecard[0] : null);

                    console.log("First Batsman Object Keys:", Object.keys(bat || {}));
                    console.log("First Batsman Object Data:", JSON.stringify(bat, null, 2));

                    // Check specific likely keys
                    if (bat) {
                        console.log("Dismissal check:", bat.dismissal, bat.outDesc, bat.status, bat.howOut);
                    }
                } else {
                    console.log("No innings data found");
                }
            } else {
                console.log("No score details");
            }
        } catch (e) {
            console.error(e);
        }
    });
});
