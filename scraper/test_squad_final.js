// Direct test with exact parameters from screenshot
const matchId = '1565683';
const apiKey = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const apiHost = 'cricketapi2.p.rapidapi.com';

async function testSquad() {
    const url = `https://${apiHost}/matches/v1/match/squad?matchId=${matchId}`;

    console.log('URL:', url);

    const resp = await fetch(url, {
        headers: {
            'x-rapidapi-key': apiKey,
            'x-rapidapi-host': apiHost
        }
    });

    console.log('Status:', resp.status);
    const text = await resp.text();
    console.log('Response:', text);

    if (resp.ok) {
        try {
            const data = JSON.parse(text);
            console.log('\nParsed:');
            console.log('- Has items:', !!data.items);
            console.log('- Items length:', data.items?.length);
            if (data.items?.[0]) {
                console.log('- Team A:', data.items[0].name);
                console.log('- Players:', data.items[0].players?.length);
            }
        } catch (e) {
            console.log('Parse error:', e.message);
        }
    }
}

testSquad().catch(console.error);
