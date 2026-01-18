const axios = require('axios');
const fs = require('fs');
const apiKey = '0f7ca5bd05msh3c4666a53a408e7p18a355jsnf0b0ef39619e';
const apiHost = 'cricbuzz-cricket2.p.rapidapi.com';
const seriesId = '11176';

async function dumpSeriesSquads() {
    try {
        console.log(`Fetching Series Squads for ${seriesId}...`);
        const res = await axios.get(`https://${apiHost}/series/v1/${seriesId}/squads`, {
            headers: { 'X-RapidAPI-Key': apiKey, 'X-RapidAPI-Host': apiHost }
        });

        fs.writeFileSync('series_squads_dump.json', JSON.stringify(res.data, null, 2));
        console.log("Saved to series_squads_dump.json");

    } catch (e) {
        console.error("Error:", e.message);
    }
}

dumpSeriesSquads();
