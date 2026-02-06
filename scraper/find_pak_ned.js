
const apiKey = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'cricbuzz-cricket.p.rapidapi.com';

async function findPakNed() {
    console.log('Fetching UPCOMING matches...');
    const listUrl = `https://${host}/matches/v1/upcoming`; // Switching to upcoming

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

        console.log(`Scanning ${matches.length} upcoming matches...`);

        // Find PAK vs NED
        const target = matches.find(m =>
            (m.team1.teamName.includes('Pakistan') || m.team2.teamName.includes('Pakistan')) &&
            (m.team1.teamName.includes('Nether') || m.team2.teamName.includes('Nether'))
        );

        if (target) {
            console.log(`\n🎉 FOUND MATCH!`);
            console.log(`Match: ${target.team1.teamName} vs ${target.team2.teamName}`);
            console.log(`Match ID: ${target.matchId}`);
            console.log(`Series ID: ${target.seriesId}`);
            console.log(`Series Name: ${target.seriesName}`);
            console.log(`State: ${target.state}`);

            // Now Test Squad for THIS Match
            const squadUrl = `https://${host}/series/v1/${target.seriesId}/squads/${target.matchId}`;
            console.log(`\nChecking Squad: ${squadUrl}`);

            const sResp = await fetch(squadUrl, {
                headers: { 'x-rapidapi-key': apiKey, 'x-rapidapi-host': host, 'User-Agent': 'Mozilla/5.0' }
            });

            console.log(`Squad Status: ${sResp.status}`);
            const txt = await sResp.text();
            if (sResp.status === 200) {
                console.log('Squad Data Present!');
                // console.log(txt.substring(0, 500));
                const json = JSON.parse(txt);
                if (json.items && json.items.length > 0) console.log('Items found:', json.items.length);
            } else {
                console.log('Squad Empty:', txt);

                // Try Series Squad Fallback
                console.log('Trying Series Fallback...');
                const serUrl = `https://${host}/series/v1/${target.seriesId}/squads`;
                const r2 = await fetch(serUrl, { headers: { 'x-rapidapi-key': apiKey, 'x-rapidapi-host': host } });
                console.log(`Series List Status: ${r2.status}`);
                if (r2.ok) console.log(await r2.text());
            }

        } else {
            console.log('❌ Match found matching PAK vs NED criteria.');
            // Print some sample names to debug
            if (matches.length > 0) {
                console.log('Samples:', matches.slice(0, 5).map(m => `${m.team1.teamName} vs ${m.team2.teamName} (Series: ${m.seriesName})`));
            }
        }

    } catch (e) {
        console.error(e);
    }
}

findPakNed();
