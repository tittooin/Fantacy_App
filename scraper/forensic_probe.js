
const https = require('https');

const options = {
    method: 'GET',
    hostname: 'livescore6.p.rapidapi.com',
    port: null,
    path: '/series/v1/11253/squads/139216',
    headers: {
        'x-rapidapi-key': '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee',
        'x-rapidapi-host': 'livescore6.p.rapidapi.com',
        'User-Agent': 'Mozilla/5.0'
    }
};

const req = https.request(options, function (res) {
    const chunks = [];

    res.on('data', function (chunk) {
        chunks.push(chunk);
    });

    res.on('end', function () {
        const body = Buffer.concat(chunks);
        console.log("--- RAW API RESPONSE START ---");
        console.log(body.toString());
        console.log("--- RAW API RESPONSE END ---");
        console.log("Status Code:", res.statusCode);
    });
});

req.on('error', function (error) {
    console.error(error);
});

req.end();
