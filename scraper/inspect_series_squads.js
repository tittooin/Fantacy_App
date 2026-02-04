
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'unofficial-cricbuzz.p.rapidapi.com';
const seriesId = '10102'; // From deep_inspect_match_info.js

async function run() {
    const url = `https://${host}/series/get-squads?seriesId=${seriesId}`;
    console.log(`Fetching Series Squads: ${url}`);

    try {
        const resp = await fetch(url, {
            headers: { 'x-rapidapi-key': RAPID_API_KEY, 'x-rapidapi-host': host }
        });

        if (resp.ok) {
            const data = await resp.json();
            // Dump EVERYTHING
            console.log(JSON.stringify(data, null, 2));

            // Check if we need to go deeper (e.g. squads array inside)
            if (data.squads) {
                // ...
            }
        } else {
            console.log("Error:", resp.status);
        }
    } catch (e) {
        console.error(e);
    }
}

run();
