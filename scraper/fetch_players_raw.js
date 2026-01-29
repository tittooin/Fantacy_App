const axios = require('axios');

// Match ID from logs: 121417 (This looks like a Cricbuzz ID)
const matchId = '121417';
// Try fetching the squad page HTML
const url = `https://www.cricbuzz.com/cricket-match-squads/${matchId}/match-center`;

console.log(`Testing URL: ${url}`);

axios.get(url, {
    headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
})
    .then(response => {
        const html = response.data;
        console.log("✅ Response received. Length:", html.length);

        // Simple Regex to find player names (Very rough, but effective for a specific page structure)
        // Looking for patterns often found in their JSON/HTML embedding
        // Or just check if "Rohit" or "Kohli" exists to confirm it's the right page

        if (html.includes("Squads")) {
            console.log("✅ Page contains 'Squads'. Parsing...");

            // Extracting player names using regex (common patterns in cricbuzz)
            // This is a naive extraction for names inside anchor tags or div classes
            // We will just print the first 500 characters of a relevant section to inspect manually first
            // or try to match names.

            // Better: Find JSON embedded in script tags
            const jsonMatch = html.match(/window\.__INITIAL_STATE__\s*=\s*({.+?});/);
            if (jsonMatch) {
                console.log("Found JSON State!");
                // console.log(jsonMatch[1]); // Too large to log
            } else {
                // Fallback: look for player profile links
                // Format: <a href="/profiles/576/rohit-sharma" ... >Rohit Sharma</a>
                const players = [];
                // Regex to capture ID and Name from href and content
                // href="/profiles/(\d+)/([^"]+)" text content check

                // Simplest: Find all /profiles/ links and extract the name part form URL
                const regex = /href="\/profiles\/(\d+)\/([^"]+)"/g;
                let match;
                const seen = new Set();

                while ((match = regex.exec(html)) !== null) {
                    const id = match[1];
                    let name = match[2].replace(/-/g, ' '); // rohit-sharma -> rohit sharma
                    // Capitalize
                    name = name.split(' ').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');

                    if (!seen.has(id)) {
                        players.push({ id, name });
                        seen.add(id);
                    }
                }

                console.log(`Found ${players.length} players.`);
                if (players.length > 0) {
                    console.log("JSON_OUTPUT_START");
                    console.log(JSON.stringify(players, null, 2));
                    console.log("JSON_OUTPUT_END");
                } else {
                    // Debug: print a substring to see what links look like
                    console.log("Debug HTML substr:", html.substring(10000, 15000));
                }
            }
        } else {
            console.log("❌ Could not verify 'Squads' in content.");
        }

    })
    .catch(error => {
        console.log("❌ Error fetching:", error.message);
    });
