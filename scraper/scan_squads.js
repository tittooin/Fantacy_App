
const apiKey = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'cricbuzz-cricket.p.rapidapi.com';

async function scanForSquad() {
    console.log('Fetching recent matches...');
    const listUrl = `https://${host}/matches/v1/recent`;

    try {
        const resp = await fetch(listUrl, {
            headers: { 'x-rapidapi-key': apiKey, 'x-rapidapi-host': host, 'User-Agent': 'Mozilla/5.0' }
        });
        const data = await resp.json();
        const matches = [];

        // Flatten match list
        if (data.typeMatches) {
            data.typeMatches.forEach(tm => {
                if (tm.seriesMatches) {
                    tm.seriesMatches.forEach(sm => {
                        if (sm.seriesAdWrapper && sm.seriesAdWrapper.matches) {
                            sm.seriesAdWrapper.matches.forEach(m => {
                                if (m.matchInfo) matches.push(m.matchInfo);
                            });
                        }
                    });
                }
            });
        }

        console.log(`Scanning ${matches.length} matches for Squad Data...`);

        // Try up to 10 completed matches
        let found = false;
        let count = 0;

        for (const m of matches) {
            if (count >= 10) break;

            // Check Upcoming/Preview matches
            if (m.state !== 'Preview' && m.state !== 'Upcoming') continue;

            const squadUrl = `https://${host}/series/v1/${m.seriesId}/squads/${m.matchId}`;
            // console.log(`Checking ${m.matchId} (${m.team1.teamName} vs ${m.team2.teamName})...`);

            const sResp = await fetch(squadUrl, {
                headers: { 'x-rapidapi-key': apiKey, 'x-rapidapi-host': host, 'User-Agent': 'Mozilla/5.0' }
            });

            if (sResp.status === 200) {
                console.log(`\n🎉 SUCCESS! Match ${m.matchId} has squad data!`);
                console.log(`Teams: ${m.team1.teamName} vs ${m.team2.teamName}`);
                const txt = await sResp.text();
                console.log('Sample Data:', txt.substring(0, 300));

                // Parse to confirm players structure
                const json = JSON.parse(txt);
                if (json.items && json.items.length > 0) {
                    console.log('Structure confirmed: items[].players exists.');
                }
                found = true;
                break;
            } else {
                process.stdout.write('.'); // Progress dot
            }
            count++;
        }

        if (!found) console.log('\n❌ Checked 10 matches, all returned 204/Error.');

    } catch (e) {
        console.error(e);
    }
}

scanForSquad();
