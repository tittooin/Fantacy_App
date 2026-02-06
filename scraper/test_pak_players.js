
const apiKey = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'cricbuzz-cricket.p.rapidapi.com';
const seriesId = '11253';
const squadId = '110157'; // Pakistan

async function testPlayers() {
    const url = `https://${host}/series/v1/${seriesId}/squads/${squadId}/players`;
    // Or just .../squads/{squadId} -- let's try both if one fails. 
    // Actually my worker uses .../squads/{squadId}/players based on assumption. 
    // Let's test THAT assumption.

    console.log(`Fetching Players: ${url}`);

    try {
        let resp = await fetch(url, {
            headers: { 'x-rapidapi-key': apiKey, 'x-rapidapi-host': host, 'User-Agent': 'Mozilla/5.0' }
        });

        if (resp.status !== 200) {
            console.log(`Failed with /players subpath (Status ${resp.status}). Trying without...`);
            const url2 = `https://${host}/series/v1/${seriesId}/squads/${squadId}`;
            resp = await fetch(url2, {
                headers: { 'x-rapidapi-key': apiKey, 'x-rapidapi-host': host, 'User-Agent': 'Mozilla/5.0' }
            });
        }

        console.log(`Final Status: ${resp.status}`);
        const txt = await resp.text();

        if (resp.ok) {
            console.log('Success! Length:', txt.length);
            // console.log(txt.substring(0, 500));
            const json = JSON.parse(txt);
            if (json.player) {
                console.log(`Found ${json.player.length} players!`);
                console.log('Sample:', json.player[0].name);
            } else {
                console.log('JSON structure different:', Object.keys(json));
            }
        } else {
            console.log('Error:', txt);
        }

    } catch (e) {
        console.error(e);
    }
}

testPlayers();
