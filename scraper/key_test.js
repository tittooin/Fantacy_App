const axios = require('axios');

const apiKey = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const apiHost = 'cricbuzz-cricket.p.rapidapi.com';

async function testApi() {
    try {
        console.log("Testing matches/v1/upcoming...");
        const res = await axios.get(`https://${apiHost}/matches/v1/upcoming`, {
            headers: {
                'X-RapidAPI-Key': apiKey,
                'X-RapidAPI-Host': apiHost
            }
        });
        console.log("Status:", res.status);
        console.log("Data Type:", typeof res.data);
        if (res.data && res.data.typeMatches) {
            console.log("Success! Found typeMatches.");
            console.log("Count:", res.data.typeMatches.length);
            console.log("Sample:", JSON.stringify(res.data.typeMatches[0], null, 2));
        } else {
            console.log("Response Body:", JSON.stringify(res.data, null, 2));
        }
    } catch (e) {
        console.error("Error:", e.message);
        if (e.response) console.error("Response:", e.response.data);
    }
}

testApi();
