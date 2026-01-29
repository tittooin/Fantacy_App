const https = require('https');

const matchId = '121417'; // Match ID from logs
const url = `https://fantasy-cricket-api.moremagical4.workers.dev/api/squads?matchId=${matchId}`;

console.log(`📡 Fetching: ${url}`);

https.get(url, (res) => {
    let data = '';

    res.on('data', (chunk) => {
        data += chunk;
    });

    res.on('end', () => {
        console.log(`✅ Status: ${res.statusCode}`);
        try {
            const json = JSON.parse(data);
            console.log('🔍 Response:', JSON.stringify(json, null, 2));

            if (Array.isArray(json) && json.length === 0) {
                console.log('❌ Result is an EMPTY ARRAY.');
            } else if (json.players && json.players.length === 0) {
                console.log('❌ Result has EMPTY players list.');
            } else {
                console.log('✅ Data found!');
            }
        } catch (e) {
            console.log('❌ Error parsing JSON:', e);
            console.log('Raw Data:', data);
        }
    });

}).on('error', (err) => {
    console.log('❌ Error:', err.message);
});
