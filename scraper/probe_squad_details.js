const axios = require('axios');
const apiKey = '0f7ca5bd05msh3c4666a53a408e7p18a355jsnf0b0ef39619e';
const apiHost = 'cricbuzz-cricket2.p.rapidapi.com';
const seriesId = '11176';
const squadId = '109032'; // West Indies

async function test(path) {
    try {
        console.log(`\nTesting ${path}...`);
        const res = await axios.get(`https://${apiHost}${path}`, {
            headers: { 'X-RapidAPI-Key': apiKey, 'X-RapidAPI-Host': apiHost }
        });
        console.log(`✅ Status: ${res.status}`);
        const dataStr = JSON.stringify(res.data);
        if (dataStr.includes('name') || dataStr.includes('role')) {
            console.log("Looks like it has PLAYER DATA!");
            console.log(JSON.stringify(res.data, null, 2).substring(0, 500));
        } else {
            console.log("No obvious player data found.");
        }

    } catch (e) {
        console.log(`❌ Error: ${e.message} (${e.response?.status})`);
    }
}

async function run() {
    await test(`/series/v1/${seriesId}/squads/${squadId}`);
    await test(`/squads/v1/${squadId}`);
    // await test(`/team/v1/10/players`); // Team ID 10
}

run();
