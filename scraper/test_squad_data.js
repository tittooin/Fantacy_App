const axios = require('axios');
const fs = require('fs');

const apiKey = '0f7ca5bd05msh3c4666a53a408e7p18a355jsnf0b0ef39619e';
const apiHost = 'cricbuzz-cricket2.p.rapidapi.com';
const matchId = '137819'; // AFG vs WI

async function fetchSquads() {
    try {
        console.log(`Fetching Squads (scov2) for ${matchId}...`);
        const res = await axios.get(`https://${apiHost}/mcenter/v1/${matchId}/scov2`, {
            headers: {
                'X-RapidAPI-Key': apiKey,
                'X-RapidAPI-Host': apiHost
            }
        });

        console.log("Status:", res.status);
        if (res.data.matchInfo) {
            const t1 = res.data.matchInfo.team1;
            const t2 = res.data.matchInfo.team2;
            console.log(`Team 1 (${t1.teamName}): ${t1.playerDetails ? t1.playerDetails.length : 0} players`);
            console.log(`Team 2 (${t2.teamName}): ${t2.playerDetails ? t2.playerDetails.length : 0} players`);
        } else {
            console.log("No matchInfo found");
        }

    } catch (e) {
        console.error("Error:", e.message);
        if (e.response) console.log(e.response.data);
    }
}

fetchSquads();
