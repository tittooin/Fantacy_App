const axios = require('axios');

async function debugMatches() {
    const workerUrl = 'https://fantasy-cricket-api.moremagical4.workers.dev';
    try {
        console.log("📡 Fetching matches from Worker...");
        const response = await axios.get(`${workerUrl}/api/get-matches`);
        const data = response.data;

        if (data.success && data.matches && data.matches.length > 0) {
            console.log(`✅ Success! Received ${data.matches.length} matches.`);
            console.log("\n--- FULL RAW DATA FOR FIRST MATCH ---");
            console.log(JSON.stringify(data.matches[0], null, 2));
        } else {
            console.log("❌ Error:", data.error || data.message);
        }
    } catch (e) {
        console.log("❌ Axios Error:", e.message);
    }
}

debugMatches();
