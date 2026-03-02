const axios = require('axios');

const HEADERS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/121.0'
];

function getRandomHeader() {
    return HEADERS[Math.floor(Math.random() * HEADERS.length)];
}

async function fetchLiveScores() {
    console.log("🚀 Starting Smart Scraper...");
    try {
        const { data } = await axios.get('https://www.cricbuzz.com/cricket-match/live-scores', {
            headers: {
                'User-Agent': getRandomHeader(),
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
            }
        });

        const regex = /<a href="\/live-cricket-scores\/(\d+)\/([^"]+)"[^>]*title="([^"]+)"/g;
        let m;
        const matches = [];
        const unique = new Set();

        while ((m = regex.exec(data)) !== null) {
            const matchId = m[1];
            if (!unique.has(matchId)) {
                unique.add(matchId);

                let team1 = "T1", team2 = "T2";
                const teamMatch = m[2].match(/^([a-z]+)-vs-([a-z]+)/);
                if (teamMatch) {
                    team1 = teamMatch[1].toUpperCase();
                    team2 = teamMatch[2].toUpperCase();
                }

                // Determine basic status from title
                const title = m[3];
                let status = "Upcoming";
                if (title.toLowerCase().includes('complete') || title.toLowerCase().includes('won')) status = "Completed";
                else if (title.toLowerCase().includes('stumps') || title.toLowerCase().includes('live') || title.toLowerCase().includes('toss') || title.toLowerCase().includes('innings break')) status = "Live";
                else if (title.toLowerCase().includes('abandon')) status = "Abandoned";

                matches.push({
                    id: matchId,
                    slug: m[2],
                    title: title,
                    teamA: team1,
                    teamB: team2,
                    status: status
                });
            }
        }

        console.log(`✅ Found ${matches.length} distinct matches.`);

        // Let's dig deeper into the first Live Match to extract score
        const liveMatch = matches.find(m => m.status === 'Live');
        if (liveMatch) {
            console.log(`🔍 Scraping Scorecard for Live Match: ${liveMatch.title}`);
            const { data: mcData } = await axios.get(`https://www.cricbuzz.com/api/html/homepage-scag`, {
                headers: { 'User-Agent': getRandomHeader() }
            });
            // Cricbuzz uses a small API endpoint for homepage scores `homepage-scag`
            // Let's see if the match is in there
            if (mcData.includes(liveMatch.id)) {
                console.log(`Live Match ${liveMatch.id} block found in Homepage Scag.`);
            } else {
                console.log(`Fallback: Scraping match HTML page directly for ${liveMatch.id}`);
            }
        } else {
            console.log("No live matches to test scorecard right now.");
        }

        console.log("Preview of parsed matches:", matches.slice(0, 3));

    } catch (e) {
        console.error("Scraper Error:", e.message);
    }
}
fetchLiveScores();
