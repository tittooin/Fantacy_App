
const matchId = '121422';
const seriesId = '10102';
const apiKey = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'cricbuzz-cricket.p.rapidapi.com';

async function testLiveSquad() {
    const url = `https://${host}/series/v1/${seriesId}/squads/${matchId}`;
    console.log(`Testing with known match: ${url}`);

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
            try {
                const data = JSON.parse(text);
                // Log structure
                console.log('Keys:', Object.keys(data));
                if (data.reponse) console.log('Response keys:', Object.keys(data.reponse)); // Cricbuzz likely uses 'reponse' or 'items' or root array

                // Try to find items/players
                // Based on previous cricketapi2 findings, it might be items[].players
                // But let's dump a customized summary
                console.log('Raw sample (first 500 chars):', text.substring(0, 500));

            } catch (e) {
                console.log('JSON Parse Error:', e.message);
                console.log('Raw Text:', text);
            }
        } else {
            console.log('Error:', text);
        }

    } catch (e) {
        console.log('Fetch Error:', e.message);
    }
}

testLiveSquad();
