const axios = require('axios');
const apiKey = '0f7ca5bd05msh3c4666a53a408e7p18a355jsnf0b0ef39619e';
const apiHost = 'cricbuzz-cricket2.p.rapidapi.com';
const matchId = '137819';
const seriesId = '11176';

async function test(path) {
    try {
        console.log(`\nTesting ${path}...`);
        const res = await axios.get(`https://${apiHost}${path}`, {
            headers: { 'X-RapidAPI-Key': apiKey, 'X-RapidAPI-Host': apiHost }
        });
        console.log(`✅ Status: ${res.status}`);
        // console.log(JSON.stringify(res.data).substring(0, 200));

        // Check for players
        const dataStr = JSON.stringify(res.data);
        if (dataStr.includes('playerDetails') || dataStr.includes('squad') || dataStr.includes('Rashid')) {
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
    await test(`/mcenter/v1/${matchId}/scov2`); // Original (Failed)
    await test(`/mcenter/v1/${matchId}/scorecard`); // Alternative 1
    await test(`/mcenter/v1/${matchId}`); // Alternative 2
    await test(`/matches/v1/${matchId}/scorecard`); // Alternative 3
    await test(`/matches/v1/${matchId}/squads`); // Alternative 4
    await test(`/series/v1/${seriesId}/squads`); // Alternative 5
}

run();
