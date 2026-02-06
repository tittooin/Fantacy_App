
const matchId = '121422';
const apiKey = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'cricbuzz-cricket.p.rapidapi.com';

async function testScorecard() {
    console.log(`Testing Scorecard for ${matchId}...`);
    const url = `https://${host}/mcenter/v1/${matchId}/hscard`;

    try {
        const resp = await fetch(url, {
            headers: {
                'x-rapidapi-key': apiKey,
                'x-rapidapi-host': host,
                'User-Agent': 'Mozilla/5.0'
            }
        });

        console.log(`Status: ${resp.status}`);
        if (resp.status === 200) {
            const data = await resp.json();
            console.log('Keys:', Object.keys(data));

            if (data.scorecard && data.scorecard.length > 0) {
                const innings = data.scorecard[0];
                const batsmen = innings.batsman || [];
                const bowlers = innings.bowler || [];

                console.log(`Found ${batsmen.length} Batsmen and ${bowlers.length} Bowlers in Innings 1`);
                if (batsmen.length > 0) console.log('Sample Bat:', batsmen[0].name);
            } else {
                console.log('No scorecard data found.');
            }
        } else {
            const txt = await resp.text();
            console.log('Error:', txt.substring(0, 200));
        }

    } catch (e) {
        console.error(e);
    }
}

testScorecard();
