const axios = require('axios');
const API_KEY = "0f7ca5bd05msh3c4666a53a408e7p18a355jsnf0b0ef39619e"; // From diag_key.js

async function getMatchId() {
    try {
        console.log("Fetching Upcoming Matches...");
        const res = await axios.get('https://cricbuzz-cricket2.p.rapidapi.com/matches/v1/upcoming', {
            headers: {
                'X-RapidAPI-Key': API_KEY,
                'X-RapidAPI-Host': 'cricbuzz-cricket2.p.rapidapi.com'
            }
        });

        const typeMatches = res.data.typeMatches || [];
        for (const type of typeMatches) {
            if (type.seriesMatches) {
                for (const series of type.seriesMatches) {
                    const seriesData = series.seriesAdWrapper || series;
                    if (seriesData.matches) {
                        for (const match of seriesData.matches) {
                            const info = match.matchInfo;
                            console.log(`\nFound Match: ${info.matchId} (Series: ${info.seriesId}) - ${info.team1.teamName} vs ${info.team2.teamName}`);

                            // Inspect Team 1 Players
                            if (info.team1.playerDetails) {
                                console.log("Team 1 Players:");
                                info.team1.playerDetails.forEach(p => console.log(`  ${p.name}: ${p.role}`));
                            } else {
                                console.log("  No playerDetails for Team 1");
                            }

                            // Inspect Team 2 Players
                            if (info.team2.playerDetails) {
                                console.log("Team 2 Players:");
                                info.team2.playerDetails.forEach(p => console.log(`  ${p.name}: ${p.role}`));
                            }

                            if (info.team1.playerDetails || info.team2.playerDetails) return; // Exit after first match with players
                        }
                    }
                }
            }
        }
    } catch (e) {
        console.error(e);
    }
}

getMatchId();
