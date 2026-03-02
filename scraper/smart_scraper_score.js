const axios = require('axios');

const HEADERS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/121.0'
];

async function fetchMatchScore(matchId) {
    try {
        console.log(`Fetching Score for Match ${matchId}`);
        const { data } = await axios.get(`https://www.cricbuzz.com/live-cricket-scores/${matchId}`, {
            headers: { 'User-Agent': HEADERS[0] }
        });

        // The live score usually looks like: <div class="cb-min-bat-rw"><span class="cb-font-20 text-bold">PAK 150/4 (18.2 Ovs)</span></div>
        // or <div class="cb-font-20 text-bold">IND 200/5 (20 Ovs)</div>

        const scoreMatch = data.match(/<span class="cb-font-20 text-bold">([^<]+)<\/span>/) || data.match(/<div class="cb-min-bat-rw">[^>]*>([^<]+)</);

        if (scoreMatch) {
            console.log(`✅ Extracted Score Text: ${scoreMatch[1]}`);
        } else {
            console.log(`❌ No Score Match Found in HTML`);
        }
    } catch (e) {
        console.error("Score Error:", e.message);
    }
}
fetchMatchScore('139450'); // Zim vs Rsa (Toss)
fetchMatchScore('139448'); // Pak vs SL (Complete)
