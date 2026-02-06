const matchId = '1565683';
const apiKey = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
// Try alternative host seen in previous screenshot
const apiHost = 'cricbuzz-cricket.p.rapidapi.com';

async function testSquad() {
    const url = `https://${apiHost}/matches/v1/match/squad?matchId=${matchId}`;
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

testSquad();
