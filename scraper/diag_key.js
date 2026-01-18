const axios = require('axios');

const apiKey = '0f7ca5bd05msh3c4666a53a408e7p18a355jsnf0b0ef39619e';
const apiHost = 'cricbuzz-cricket2.p.rapidapi.com';

async function testEndpoint(name, path) {
    try {
        console.log(`\nTesting ${name} (${path})...`);
        const res = await axios.get(`https://${apiHost}${path}`, {
            headers: {
                'X-RapidAPI-Key': apiKey,
                'X-RapidAPI-Host': apiHost
            }
        });
        console.log(`✅ Status: ${res.status}`);
        if (res.data) {
            const keys = Object.keys(res.data);
            console.log(`   Keys: ${keys.join(', ')}`);
            if (res.data.typeMatches) console.log(`   typeMatches: ${res.data.typeMatches.length}`);
            if (res.data.matches) console.log(`   matches: ${res.data.matches.length}`);
        }
    } catch (e) {
        console.log(`❌ Error: ${e.message}`);
        if (e.response) {
            console.log(`   Status: ${e.response.status}`);
            console.log(`   Data: ${JSON.stringify(e.response.data)}`);
        }
    }
}

async function run() {
    await testEndpoint('Upcoming V1', '/matches/v1/upcoming');
    await testEndpoint('List Upcoming', '/matches/list-upcoming');
    await testEndpoint('Recent V1', '/matches/v1/recent');
    await testEndpoint('Live V1', '/matches/v1/live');
}

run();
