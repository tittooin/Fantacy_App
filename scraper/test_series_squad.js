const matchId = '1565683';
const seriesId = '22358';
const apiKey = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const apiHost = 'cricketapi2.p.rapidapi.com';

async function testSeriesSquad() {
    const url = `https://${apiHost}/series/v1/${seriesId}/squads/${matchId}`;
    console.log('Testing URL:', url);

    const resp = await fetch(url, {
        headers: {
            'x-rapidapi-key': apiKey,
            'x-rapidapi-host': apiHost
        }
    });

    console.log('Status:', resp.status);
    const text = await resp.text();
    console.log('Response:', text);
}

testSeriesSquad();
