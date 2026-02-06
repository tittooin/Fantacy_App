
// Use global fetch (Node 22+)
const matchId = '1565683';
const apiKey = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'cricketapi2.p.rapidapi.com';

async function probe() {
    const endpoints = [
        `/matches/v1/match/squad?matchId=${matchId}`,
        `/matches/v1/recent` // Verify API reachability
    ];

    const extraHeaders = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'application/json',
        'Content-Type': 'application/json'
    };

    console.log('--- Probing cricketapi2 (Correct Host) ---');
    for (const ep of endpoints) {
        const url = `https://${host}${ep}`;
        console.log(`Checking ${url}...`);
        try {
            const resp = await fetch(url, {
                headers: {
                    'x-rapidapi-key': apiKey,
                    'x-rapidapi-host': host,
                    ...extraHeaders
                }
            });
            console.log(`Status: ${resp.status}`);
            const txt = await resp.text();
            console.log(`Resp len: ${txt.length}`);
            if (resp.status === 200) console.log(txt.substring(0, 300));
            else console.log('Error Resp:', txt.substring(0, 200));
        } catch (e) {
            console.log('Err:', e.message);
        }
        console.log('---');
    }

    console.log('\n--- Probing cricbuzz-cricket (Mismatch Host) ---');
    // Testing the mismatch hypothesis: URL=cricbuzz, Host=cricbuzz
    // AND URL=cricketapi2, Host=cricbuzz

    // 1. Host Mismatch: URL=cricketapi2, Header=cricbuzz-cricket
    const mismatchHost = 'cricbuzz-cricket.p.rapidapi.com';
    const mismatchUrl = `https://${host}/matches/v1/match/squad?matchId=${matchId}`;
    console.log(`Checking Mismatch Header: ${mismatchUrl} with Host: ${mismatchHost}`);
    try {
        const resp = await fetch(mismatchUrl, {
            headers: {
                'x-rapidapi-key': apiKey,
                'x-rapidapi-host': mismatchHost,
                ...extraHeaders
            }
        });
        console.log(`Status: ${resp.status}`);
        const txt = await resp.text();
        console.log(`Resp len: ${txt.length}`);
    } catch (e) { console.log('Err:', e.message); }
}

probe();
