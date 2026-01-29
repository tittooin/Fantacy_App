const axios = require('axios');

// Match ID for IND vs NZ 4th T20I (from user context)
const matchId = '121417';
const url = `https://www.cricbuzz.com/cricket-match-squads/${matchId}/match-center`;

console.log(`📡 Fetching Facelifted Squads from: ${url}`);

axios.get(url, {
    headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
})
    .then(response => {
        const html = response.data;
        console.log("✅ Response received.");

        // Strategy:
        // Cricbuzz usually has a structure like:
        // <div class="..."> ... <a href="/profiles/123/name"> ... <img src=".../face/123.jpg" ...> ... </a>
        // We will look for the image tag specifically associated with players.
        // The player ID in the profile link is the key.

        // Regex explanation:
        // 1. Look for href="/profiles/(\d+)/([^"]+)" (Capture ID and Name)
        // 2. Look nearby for src="([^"]+)" which contains 'face' or 'profile'

        // Since regex parsing HTML is fragile, we will iterate through profile links and then try to find the image URL that likely belongs to it.
        // Actually, cricbuzz images follow a pattern: https://static.cricbuzz.com/a/img/v1/152x152/i1/c{ID}/...jpg
        // If we get the ID, we can Construct the URL!
        // Let's verify this hypothesis.

        // Example from public knowledge: https://static.cricbuzz.com/a/img/v1/152x152/i1/c7634/rohit-sharma.jpg ??
        // Actually, usually it's just the ID.

        const players = [];
        const profileRegex = /href="\/profiles\/(\d+)\/([^"]+)"/g;
        let match;
        const seen = new Set();

        const team1Name = "IND"; // Inferred
        const team2Name = "NZ";  // Inferred

        // We need to determine which team they belong to.
        // In the HTML, there are usually two main containers for squads.
        // Splitting by team headers might be necessary if we want accurate team assignment.

        // Rough split
        const parts = html.split('Squads');
        // Usually the page lists one team then the other.

        while ((match = profileRegex.exec(html)) !== null) {
            const id = match[1];
            let nameSlug = match[2];
            let name = nameSlug.replace(/-/g, ' ').split(' ').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');

            if (!seen.has(id)) {
                // Construct Image URL
                // Common Cricbuzz pattern: https://images.cricbuzz.com/player-images/{id}.jpg (Old)
                // New: https://static.cricbuzz.com/a/img/v1/152x152/i1/c{id}/... (this is complex)

                // Let's try to find if the image src is present in the HTML for this ID.
                // We look for a string like: source path=.../c{id}/...

                // Dynamic Regex for this specific ID's image
                // Pattern: src=".../c{id}/..."
                const imgRegex = new RegExp(`src="([^"]*c${id}[^"]*)"`);
                const imgMatch = html.match(imgRegex);

                let imgUrl = "";
                if (imgMatch) {
                    imgUrl = imgMatch[1];
                    // Ensure it's absolute
                    if (imgUrl.startsWith('//')) imgUrl = "https:" + imgUrl;
                } else {
                    // Fallback pattern if not found explicitly
                    imgUrl = `https://static.cricbuzz.com/a/img/v1/152x152/i1/c${id}/i.jpg`;
                }

                // Guessing Team based on Position in file? 
                // This is risky.
                // For now, we will extract them all, and letting the user manually assign or we use known lists.
                // Or better: We leave team assignment to the existing logic which was 50/50 split, 
                // BUT we can check if "IND" or "NZ" header appeared recently.

                players.push({
                    id: id,
                    name: name,
                    username: nameSlug, // helpful for url construction
                    image: imgUrl,
                    role: "Unknown", // We will refine this if possible
                    credits: 9.0 // Default
                });
                seen.add(id);
            }
        }

        console.log(`Found ${players.length} players with images.`);

        // Output valid JSON for direct consumption
        console.log("JSON_START");
        console.log(JSON.stringify(players, null, 2));
        console.log("JSON_END");
    })
    .catch(err => console.error(err));
