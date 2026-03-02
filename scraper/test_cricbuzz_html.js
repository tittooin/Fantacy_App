const axios = require('axios');

async function scrapeMatches() {
    try {
        const url = 'https://www.cricbuzz.com/cricket-match/live-scores';
        console.log("Fetching", url);
        const { data } = await axios.get(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
            }
        });

        console.log("Got HTML:", data.length, "bytes");

        // Simple Regex to extract match items
        // Look for: <a href="/live-cricket-scores/12345/abc-vs-xyz-match-1" title="ABC vs XYZ, Match 1"...
        const matches = [];
        const regex = /<a href="\/live-cricket-scores\/(\d+)\/([^"]+)"[^>]*title="([^"]+)"/g;
        let m;
        const unique = new Set();

        while ((m = regex.exec(data)) !== null) {
            const matchId = m[1];
            if (!unique.has(matchId)) {
                unique.add(matchId);
                matches.push({
                    id: matchId,
                    slug: m[2],
                    title: m[3]
                });
            }
        }

        console.log("First 5 Match Titles:", matches.slice(0, 5));
        console.log("Total Matches Found:", matches.length);

        // Also let's try to extract a score string. Usually in `<div class="cb-hmscg-bat-txt...">Score</div>`
        // Since it's a list, the DOM is huge. We just need the ID, Team1, Team2, and state to start.

    } catch (e) {
        console.error("Error:", e.message);
    }
}

scrapeMatches();
