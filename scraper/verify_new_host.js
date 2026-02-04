
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'unofficial-cricbuzz.p.rapidapi.com';

async function run() {
    console.log(`🔍 Testing New Host: ${host} ...\n`);
    try {
        // User screenshot shows: /matches/get-schedules?matchtype=international
        const url = `https://${host}/matches/get-schedules?matchtype=international`;
        console.log(`Fetching: ${url}`);

        const res = await fetch(url, {
            headers: {
                'x-rapidapi-key': RAPID_API_KEY,
                'x-rapidapi-host': host,
                'User-Agent': 'Mozilla/5.0'
            }
        });

        if (res.ok) {
            const data = await res.json();
            console.log(`✅ Success! Response Status: ${res.status}`);

            // Log structure to verify matches
            if (data.seriesMatches) {
                console.log(`Found 'seriesMatches' array. Length: ${data.seriesMatches.length}`);
                // Inspect first series
                if (data.seriesMatches.length > 0) {
                    const firstSeries = data.seriesMatches[0];
                    if (firstSeries.seriesAdWrapper && firstSeries.seriesAdWrapper.matches) {
                        console.log("Matches in first series:", firstSeries.seriesAdWrapper.matches.length);
                        console.log("Sample Match:", JSON.stringify(firstSeries.seriesAdWrapper.matches[0], null, 2));
                    }
                }
            } else if (data.matchScheduleMap) {
                console.log("Found 'matchScheduleMap'. (Earlier format)");
            } else {
                console.log("Unknown Data Structure. printing keys:", Object.keys(data));
                console.log(JSON.stringify(data, null, 2).substring(0, 1000));
            }
        } else {
            console.log(`❌ Error: ${res.status} - ${res.statusText}`);
            const text = await res.text();
            console.log("Body:", text);
        }
    } catch (e) {
        console.log(`❌ Exception: ${e.message}`);
    }
}
run();
