
const matchId = '1565683';
const seriesId = '22358'; // From DB for this match
const apiKey = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'cricbuzz-cricket.p.rapidapi.com';

async function probeCricbuzz() {
    const endpoints = [
        // Endpoint from Step 8570 (Series Squad)
        `/series/v1/${seriesId}/squads/${matchId}`,

        // Common listing to check connectivity
        `/matches/v1/recent`,

        // Scorecard endpoint seen in Step 8488 (just to verify host works)
        `/mcenter/v1/40301/hscard`
    ];

    const extraHeaders = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'application/json'
    };

    console.log(`--- Probing ${host} ---`);
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

            if (resp.status === 200) {
                console.log(`SUCCESS! Resp len: ${txt.length}`);
                console.log(txt.substring(0, 300));
            } else {
                console.log(`Error: ${txt.substring(0, 200)}`);
            }
        } catch (e) {
            console.log('Exception:', e.message);
        }
        console.log('---');
    }
}

probeCricbuzz();
