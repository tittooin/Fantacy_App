const https = require('https');
const fs = require('fs');

const apiKey = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'cricbuzz-cricket.p.rapidapi.com';

const seriesId = '11253';
const matchId = '139252';

const optionsSeries = {
    method: 'GET',
    hostname: host,
    port: null,
    path: `/series/v1/${seriesId}/squads`,
    headers: {
        'x-rapidapi-key': apiKey,
        'x-rapidapi-host': host
    }
};

const optionsScard = {
    method: 'GET',
    hostname: host,
    port: null,
    path: `/mcenter/v1/${matchId}/scard`,
    headers: {
        'x-rapidapi-key': apiKey,
        'x-rapidapi-host': host
    }
};

function makeRequest(label, options, filename) {
    console.log(`fetching ${label}...`);
    const req = https.request(options, function (res) {
        const chunks = [];
        res.on('data', function (chunk) {
            chunks.push(chunk);
        });
        res.on('end', function () {
            const body = Buffer.concat(chunks);
            console.log(`${label} status: ${res.statusCode}`);
            fs.writeFileSync(filename, body.toString());
            console.log(`Saved ${label} response to ${filename}`);
        });
    });
    req.on('error', (e) => console.error(`${label} Error:`, e));
    req.end();
}

makeRequest('SERIES_SQUADS', optionsSeries, 'debug_squads_response.json');
makeRequest('MATCH_SCARD', optionsScard, 'debug_scard_response.json');
