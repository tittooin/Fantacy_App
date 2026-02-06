const fetch = require('node-fetch');

const matchId = '1565683';
const apiKey = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const apiHost = 'cricketapi2.p.rapidapi.com';

async function testSquad() {
    const url = `https://${apiHost}/squad/${matchId}`;

    const resp = await fetch(url, {
        headers: {
            'x-rapidapi-key': apiKey,
            'x-rapidapi-host': apiHost
        }
    });

    console.log('Status:', resp.status);
    const data = await resp.json();
    console.log('Response:', JSON.stringify(data, null, 2));
}

testSquad().catch(console.error);
