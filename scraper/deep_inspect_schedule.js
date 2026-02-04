
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'free-cricbuzz-cricket-api.p.rapidapi.com';

async function run() {
    console.log(`🔍 Deep Inspecting /cricket-schedule for International Matches...\n`);
    try {
        const res = await fetch(`https://${host}/cricket-schedule`, {
            headers: {
                'x-rapidapi-key': RAPID_API_KEY,
                'x-rapidapi-host': host,
                'User-Agent': 'Mozilla/5.0'
            }
        });

        if (res.ok) {
            const data = await res.json();
            // console.log("Raw Data Keys:", Object.keys(data));

            // Usually data is { "matchScheduleMap": [ ... ] } or similar structure
            // Let's traverse and find matches

            let matchesFound = [];

            const schedule = data.matchScheduleMap || [];

            for (const section of schedule) {
                if (section.scheduleAdWrapper) {
                    const matches = section.scheduleAdWrapper.matches || [];
                    for (const match of matches) {
                        const t1 = match.team1?.teamName || "";
                        const t2 = match.team2?.teamName || "";
                        const series = match.seriesName || "";
                        const format = match.matchFormat || "";

                        // Filter for relevant teams or International
                        if (
                            t1.includes("India") || t2.includes("India") ||
                            t1.includes("Pakistan") || t2.includes("Pakistan") ||
                            t1.includes("Australia") || t2.includes("Australia") ||
                            t1.includes("New Zealand") || t2.includes("New Zealand") ||
                            t1.includes("South Africa") || t2.includes("South Africa") ||
                            t1.includes("West Indies") || t2.includes("West Indies")
                        ) {
                            matchesFound.push({
                                id: match.matchId,
                                series: series,
                                t1: t1,
                                t2: t2,
                                format: format,
                                date: new Date(parseInt(match.startDate)).toLocaleString(),
                                status: match.status
                            });
                        }
                    }
                }
            }

            console.log(`✅ Found ${matchesFound.length} Relevant International Matches:`);
            console.log(JSON.stringify(matchesFound, null, 2));

        } else {
            console.log(`Error: ${res.status}`);
        }
    } catch (e) {
        console.log(`Error: ${e.message} \nStack: ${e.stack}`);
    }
}
run();
