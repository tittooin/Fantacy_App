
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const HOST = 'livescore6.p.rapidapi.com';

async function auditStructure() {
    // Fetch Live Cricket to see structure
    const url = `https://${HOST}/matches/v2/list-live?Category=cricket`;
    console.log(`Fetching: ${url}`);

    try {
        const resp = await fetch(url, { headers: { 'x-rapidapi-key': RAPID_API_KEY, 'x-rapidapi-host': HOST } });
        if (resp.ok) {
            const data = await resp.json();

            // Log Top Level
            console.log("Keys:", Object.keys(data));

            // Navigate to Events
            const stages = data.Stages || [];
            if (stages.length > 0) {
                console.log("\n--- Sample Stage Object ---");
                console.log(JSON.stringify(stages[0], null, 2).substring(0, 500)); // Truncate

                const events = stages[0].Events || [];
                if (events.length > 0) {
                    console.log("\n--- Sample Event (Match) Object ---");
                    console.log(JSON.stringify(events[0], null, 2));

                    // Specific fields mapping check
                    const e = events[0];
                    console.log("\n--- Mapping Check ---");
                    console.log(`Match ID (Eid): ${e.Eid}`);
                    console.log(`Team 1 (T1):`, e.T1);
                    console.log(`Team 2 (T2):`, e.T2);
                    console.log(`Status (Eps): ${e.Eps}`);
                    console.log(`Score (Tr1/Tr2): ${e.Tr1} / ${e.Tr2}`);
                }
            } else {
                console.log("No Live Stages found. Trying 'list-by-date' for yesterday to get completed details...");
                await auditPast();
            }
        }
    } catch (e) { console.error("Error:", e.message); }
}

async function auditPast() {
    // Get yesterday's date YYYYMMDD
    const date = new Date();
    date.setDate(date.getDate() - 1);
    const yyyymmdd = date.toISOString().split('T')[0].replace(/-/g, '');

    const url = `https://${HOST}/matches/v2/list-by-date?Category=cricket&Date=${yyyymmdd}`;
    console.log(`Fetching Past: ${url}`);

    const resp = await fetch(url, { headers: { 'x-rapidapi-key': RAPID_API_KEY, 'x-rapidapi-host': HOST } });
    if (resp.ok) {
        const data = await resp.json();
        const stages = data.Stages || [];
        if (stages.length > 0 && stages[0].Events.length > 0) {
            console.log("\n--- Sample Past Match ---");
            console.log(JSON.stringify(stages[0].Events[0], null, 2).substring(0, 1000));
        }
    }
}

auditStructure();
