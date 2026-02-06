// Test cricketapi2 squad endpoint
const matchId = '1565683';
const apiKey = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const apiHost = 'cricketapi2.p.rapidapi.com';

async function testSquad() {
    const url = `https://${apiHost}/matches/v1/match/squad?match_id=${matchId}`;

    console.log('Testing URL:', url);

    const resp = await fetch(url, {
        headers: {
            'x-rapidapi-key': apiKey,
            'x-rapidapi-host': apiHost
        }
    });

    console.log('Status:', resp.status);
    console.log('Headers:', Object.fromEntries(resp.headers.entries()));

    const text = await resp.text();
    console.log('Raw Response:', text);

    try {
        const data = JSON.parse(text);
        console.log('Parsed JSON:', JSON.stringify(data, null, 2));
    } catch (e) {
        console.log('Not JSON:', e.message);
    }
}

testSquad().catch(console.error);
