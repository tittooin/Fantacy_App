const axios = require('axios');
const apiKey = '0f7ca5bd05msh3c4666a53a408e7p18a355jsnf0b0ef39619e';
const apiHost = 'cricbuzz-cricket2.p.rapidapi.com';

const ids = ['126620', '125620'];

async function testScov2() {
    console.log("Checking scov2 for Playing XI...");

    for (const id of ids) {
        console.log(`\n--- Testing ID: ${id} ---`);
        try {
            const res = await axios.get(`https://${apiHost}/mcenter/v1/${id}/scov2`, {
                headers: { 'X-RapidAPI-Key': apiKey, 'X-RapidAPI-Host': apiHost }
            });

            if (res.data.matchInfo && res.data.matchInfo.team1 && res.data.matchInfo.team1.playerDetails) {
                console.log(`✅ MATCH ID ${id}: Found Playing XI!`);
                console.log(`Team 1 Count: ${res.data.matchInfo.team1.playerDetails.length}`);
                console.log(`Team 2 Count: ${res.data.matchInfo.team2.playerDetails.length}`);
            } else {
                console.log(`❌ MATCH ID ${id}: No Playing XI found (Status 200, but missing details)`);
            }
        } catch (e) {
            console.log(`❌ MATCH ID ${id}: 404/Error (${e.response?.status})`);
        }
    }
}

testScov2();
