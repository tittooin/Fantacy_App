
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const HOST = 'cricbuzz-cricket.p.rapidapi.com';
const TARGET_MATCH_ID = '139029';

async function probe() {
    console.log(`🔍 Fetching Upcoming Matches from ${HOST}...`);
    const url = `https://${HOST}/matches/v1/upcoming`;

    try {
        const r = await fetch(url, {
            headers: { 'x-rapidapi-key': RAPID_API_KEY, 'x-rapidapi-host': HOST }
        });

        if (r.ok) {
            const data = await r.json();
            console.log("Keys:", Object.keys(data));

            // Parse (reuse logic from cricket_engine)
            let found = false;

            if (data.typeMatches) {
                data.typeMatches.forEach(tm => {
                    if (tm.seriesMatches) {
                        tm.seriesMatches.forEach(sm => {
                            if (sm.seriesAdWrapper && sm.seriesAdWrapper.matches) {
                                sm.seriesAdWrapper.matches.forEach(m => {
                                    const info = m.matchInfo;
                                    if (info) {
                                        // console.log(`- ${info.matchId} : ${info.seriesName}`);
                                        if (info.matchId == TARGET_MATCH_ID) {
                                            console.log("\n✅ MATCH FOUND!");
                                            console.log("Series ID:", info.seriesId);
                                            console.log("Series Name:", info.seriesName);
                                            console.log("Status:", info.status || info.state);
                                            found = true;
                                        }
                                    }
                                });
                            }
                        });
                    }
                });
            }

            if (!found) console.log(`❌ Match ${TARGET_MATCH_ID} NOT found in Upcoming list.`);

        } else {
            console.log("Fetch Failed:", r.status);
        }
    } catch (e) {
        console.error("Error:", e.message);
    }
}

probe();
