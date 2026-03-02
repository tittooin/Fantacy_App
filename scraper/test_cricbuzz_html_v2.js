const axios = require('axios');

async function scrapeMatches() {
    try {
        const url = 'https://www.cricbuzz.com/cricket-match/live-scores';
        const { data } = await axios.get(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
            }
        });

        // The match blocks are inside <div class="cb-mtch-lst cb-col cb-col-100 cb-tms-itm">
        // Split data by this class or use a broader regex.
        // Let's split using a common repeating boundary like `id="match_` or `cb-col cb-col-100 cb-ls-match`

        let matchBlocks = data.split('cb-mtch-lst cb-col cb-col-100 cb-tms-itm');
        if (matchBlocks.length === 1) {
            matchBlocks = data.split('cb-col cb-col-100 cb-ls-match');
        }

        console.log("Found match blocks:", matchBlocks.length - 1);

        const results = [];

        for (let i = 1; i < matchBlocks.length; i++) {
            const block = matchBlocks[i];

            // Extract URL and Title
            const aTagMatch = block.match(/<a href="\/live-cricket-scores\/(\d+)\/([^"]+)"[^>]*title="([^"]+)"/);
            if (!aTagMatch) continue;

            const matchId = aTagMatch[1];
            const slug = aTagMatch[2];
            let title = aTagMatch[3];

            // Extract Teams
            let team1 = "T1", team2 = "T2";
            const teamMatch = slug.match(/^([a-z]+)-vs-([a-z]+)/);
            if (teamMatch) {
                team1 = teamMatch[1].toUpperCase();
                team2 = teamMatch[2].toUpperCase();
            }

            // Extract Status Text (e.g., Stumps, Match complete, etc)
            let statusText = '';
            const statusMatch = block.match(/<div class="cb-text-[^>]+>([^<]+)<\/div>/);
            if (statusMatch) statusText = statusMatch[1].trim();

            // Extract Score
            let scoreStr = '';
            const scoreMatch = block.match(/<div class="cb-hmscg-bat-txt[^>]*cb-font-18[^>]*>([^<]+)<\/div>/) || block.match(/<div class="cb-ovr-flo cb-text-live">([^<]+)<\/div>/);
            if (scoreMatch) scoreStr = scoreMatch[1].trim();

            results.push({
                id: matchId,
                team1,
                team2,
                title,
                statusText,
                score: scoreStr
            });
        }

        console.log(results.slice(0, 5));

    } catch (e) {
        console.error(e.message);
    }
}
scrapeMatches();
