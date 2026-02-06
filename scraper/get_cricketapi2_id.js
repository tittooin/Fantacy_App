const apiKey = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const apiHost = 'cricketapi2.p.rapidapi.com';

async function getRecentMatches() {
    // Try to get live or recent matches to find a valid match ID
    const url = `https://${apiHost}/matches/v1/recent`;

    console.log('Fetching:', url);
    const resp = await fetch(url, {
        headers: {
            'x-rapidapi-key': apiKey,
            'x-rapidapi-host': apiHost
        }
    });

    console.log('Status:', resp.status);
    const text = await resp.text();

    try {
        const data = JSON.parse(text);
        console.log('Matches found:', data.items?.length || 0);
        if (data.items && data.items.length > 0) {
            console.log('Sample Match:', JSON.stringify(data.items[0], null, 2));
            return data.items[0].matchId;
        }
    } catch (e) {
        console.log('Parse error:', e.message);
        console.log('Raw:', text.substring(0, 200));
    }
    return null;
}

getRecentMatches();
