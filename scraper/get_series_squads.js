
const seriesId = '3718'; // Known active series from user example
const apiKey = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'cricbuzz-cricket.p.rapidapi.com';

async function getSquadsList() {
    // Endpoint: /series/v1/{seriesId}/squads
    const url = `https://${host}/series/v1/${seriesId}/squads`;
    console.log(`Fetching Squads List: ${url}`);

    try {
        const resp = await fetch(url, {
            headers: {
                'x-rapidapi-key': apiKey,
                'x-rapidapi-host': host,
                'User-Agent': 'Mozilla/5.0'
            }
        });

        console.log(`Status: ${resp.status}`);
        const text = await resp.text();

        if (resp.ok) {
            console.log('--- Squads List ---');
            console.log(text.substring(0, 1000));
            try {
                const data = JSON.parse(text);
                // Log simplified structure
                if (data.squads) {
                    data.squads.forEach(s => {
                        console.log(`ID: ${s.squadId}, Name: ${s.squadType || s.title || s.teamName}`);
                    });
                }
            } catch (e) { }
        } else {
            console.log('Error:', text);
        }

    } catch (e) {
        console.error(e);
    }
}

getSquadsList();
