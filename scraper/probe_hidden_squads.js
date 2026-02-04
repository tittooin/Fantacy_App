
const KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const HOST = 'livescore6.p.rapidapi.com';

async function probe() {
    // 1. Get Live Matches to find a valid Match ID
    let matchId = '145464'; // Default from logs

    try {
        const listUrl = `https://${HOST}/matches/v2/list-live?Category=cricket`;
        const r = await fetch(listUrl, { headers: { 'x-rapidapi-key': KEY, 'x-rapidapi-host': HOST } });
        const d = await r.json();
        if (d.Stages && d.Stages.length > 0) {
            matchId = d.Stages[0].Events[0].Eid;
            console.log(`Found Live Match ID: ${matchId}`);
        }
    } catch (e) { }

    // 2. Probe Scorecard / Info
    const endpoints = [
        `/matches/v2/get-scorecard?Eid=${matchId}&Category=cricket`,
        `/matches/v2/get-statistics?Eid=${matchId}&Category=cricket`,
        `/matches/v2/get-summary?Eid=${matchId}&Category=cricket`,
        `/matches/v2/get-info?Eid=${matchId}&Category=cricket`
    ];

    for (const ep of endpoints) {
        console.log(`\nProbing: ${ep}`);
        try {
            const r = await fetch(`https://${HOST}${ep}`, { headers: { 'x-rapidapi-key': KEY, 'x-rapidapi-host': HOST } });
            if (r.ok) {
                const txt = await r.text();
                // Check for player keywords
                if (txt.includes('Bts') || txt.includes('Blg') || txt.includes('Pid')) {
                    console.log(`✅ FOUND DATA! Length: ${txt.length}`);
                    console.log(`Sample: ${txt.substring(0, 200)}...`);
                } else {
                    console.log(`Empty/No Players: ${txt.substring(0, 100)}`);
                }
            } else {
                console.log(`Status: ${r.status}`);
            }
        } catch (e) { console.log(e.message); }
    }
}

probe();
