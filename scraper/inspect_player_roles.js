const axios = require('axios');
const fs = require('fs');

// Try to read API Key from known location if possible, or use hardcoded placeholder requiring user input
// For now, I'll try to find where keys are stored. 'scraper/index.js' likely has it.
// Assuming we can mock request or use the key found in 'functions/api/squads.js' if available (it isn't, it's Env).

// Hardcoded Key for Testing (User needs to replace if invalid) or read from environment
const API_KEY = "0f7ca5bd05msh3c4666a53a408e7p18a355jsnf0b0ef39619e"; // Extracted from diag_key.js

const MATCH_ID = 137819;

async function run() {
    try {
        console.log(`Fetching Squad for ${MATCH_ID}...`);
        console.log(`Fetching Squad for Match ID: ${MATCH_ID}...`);
        const response = await axios.get(`https://cricbuzz-cricket2.p.rapidapi.com/mcenter/v1/${MATCH_ID}/scov2`, {
            headers: {
                'X-RapidAPI-Key': API_KEY,
                'X-RapidAPI-Host': 'cricbuzz-cricket2.p.rapidapi.com'
            }
        });

        const data = response.data;
        if (!data.matchInfo) {
            console.log("No matchInfo found. Response:", Object.keys(data));
            return;
        }

        const team1 = data.matchInfo.team1;
        const team2 = data.matchInfo.team2;

        function printRoles(team) {
            if (!team) return;
            console.log(`\nTeam: ${team.teamName}`);

            // Check where players are (playerDetails or squad)
            const players = team.playerDetails || team.squad || [];
            if (players.length === 0) {
                console.log("  No players found in playerDetails/squad");
                return;
            }

            players.forEach(p => {
                console.log(`  ${p.name} - Role: "${p.role}" (ID: ${p.id})`);
            });
        }

        printRoles(team1);
        printRoles(team2);

    } catch (e) {
        console.error("Error:", e.message);
        if (e.response) console.error("Response:", e.response.status, e.response.data);
    }
}
run();
