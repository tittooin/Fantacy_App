const axios = require('axios');
const fs = require('fs');

const apiKey = '0f7ca5bd05msh3c4666a53a408e7p18a355jsnf0b0ef39619e';
const apiHost = 'cricbuzz-cricket2.p.rapidapi.com';

async function fetchAndSave() {
    try {
        console.log("Fetching v1/upcoming...");
        const res = await axios.get(`https://${apiHost}/matches/v1/upcoming`, {
            headers: {
                'X-RapidAPI-Key': apiKey,
                'X-RapidAPI-Host': apiHost
            }
        });

        console.log("Status:", res.status);
        fs.writeFileSync('upcoming_dump.json', JSON.stringify(res.data, null, 2));
        console.log("Saved to upcoming_dump.json");

    } catch (e) {
        console.error(e);
    }
}

fetchAndSave();
