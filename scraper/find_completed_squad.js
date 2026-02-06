
const apiKey = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'cricbuzz-cricket.p.rapidapi.com';

async function findAndTestSquad() {
    console.log('Fetching recent matches list...');
    const listUrl = `https://${host}/matches/v1/recent`;

    try {
        const resp = await fetch(listUrl, {
            headers: {
                'x-rapidapi-key': apiKey,
                'x-rapidapi-host': host,
                'User-Agent': 'Mozilla/5.0'
            }
        });

        const data = await resp.json();
        const matches = [];

        // Extract matches from complex structure
        // typeMatches -> seriesMatches -> seriesAdWrapper -> matches -> matchInfo
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

        console.log(`Found ${matches.length} matches.`);

        // Find a completed match
        const completedMatch = matches.find(m => m.state === 'Complete' || m.status?.includes('won'));

        if (completedMatch) {
            console.log(`Found Completed Match: ${completedMatch.matchId} (${completedMatch.team1.teamName} vs ${completedMatch.team2.teamName})`);
            console.log(`Series ID: ${completedMatch.seriesId}`);

            // Test Squad
            const squadUrl = `https://${host}/series/v1/${completedMatch.seriesId}/squads/${completedMatch.matchId}`;
            console.log(`Fetching Squad: ${squadUrl}`);

            const squadResp = await fetch(squadUrl, {
                headers: {
                    'x-rapidapi-key': apiKey,
                    'x-rapidapi-host': host,
                    'User-Agent': 'Mozilla/5.0'
                }
            });

            console.log(`Squad Status: ${squadResp.status}`);
            const squadText = await squadResp.text();

            if (squadResp.status === 200) {
                console.log('Squad Data Found!');
                console.log('Sample:', squadText.substring(0, 500));
            } else {
                console.log('Squad Data Empty/Error:', squadText);
            }

        } else {
            console.log('No completed matches found in recent list.');
            if (matches.length > 0) console.log('Sample Match State:', matches[0].state);
        }

    } catch (e) {
        console.error('Error:', e);
    }
}

findAndTestSquad();
