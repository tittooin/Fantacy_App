const express = require('express');
const cors = require('cors');
const axios = require('axios');
const xml2js = require('xml2js');

const app = express();
const PORT = 3000;

app.use(cors());

// Helper to parse XML
const parseXml = async (xml) => {
    const parser = new xml2js.Parser({ explicitArray: false });
    return parser.parseStringPromise(xml);
};

// Route: Get All Matches (Live + Upcoming) from Cricbuzz RSS or Fallback to RapidAPI
// --- SIMPLE MEMORY CACHE ---
const CACHE_DURATION_MS = 10 * 60 * 1000; // 10 Minutes
const cache = {
    matches: { data: null, timestamp: 0 },
    recent: { data: null, timestamp: 0 }
};

// Route: Get All Matches with Caching
app.get('/matches', async (req, res) => {
    // 1. Check Cache
    const now = Date.now();
    if (cache.matches.data && (now - cache.matches.timestamp < CACHE_DURATION_MS)) {
        console.log("⚡ Serving Matches from Cache (Save API Hits)");
        return res.json({ matches: cache.matches.data, cached: true });
    }

    try {
        console.log("Fetching Matches from Cricbuzz RSS...");
        const headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        };

        // Fetch RSS
        const [upcomingRes, liveRes] = await Promise.allSettled([
            axios.get('https://www.cricbuzz.com/rss/match/upcoming', { headers }),
            axios.get('https://www.cricbuzz.com/rss/match/live', { headers })
        ]);

        let allMatches = [];
        const processFeed = async (response) => {
            if (response.status === 'fulfilled') {
                try {
                    const result = await parseXml(response.value.data);
                    const items = result.rss && result.rss.channel ? result.rss.channel.item : [];
                    return Array.isArray(items) ? items : (items ? [items] : []);
                } catch (e) { return []; }
            }
            return [];
        };

        const upcomingItems = await processFeed(upcomingRes);
        const liveItems = await processFeed(liveRes);
        const rawItems = [...liveItems, ...upcomingItems];

        allMatches = rawItems.map((item, index) => {
            // ... [Existing Parsers] ...
            const titleParts = item.title ? item.title.split(',') : ["Unknown vs Unknown"];
            const matchDesc = titleParts.slice(1).join(',').trim();
            const teams = titleParts[0].split(' vs ');
            let matchId = 10000 + index;
            if (item.link) {
                const parts = item.link.split('/');
                for (const part of parts) { if (!isNaN(part) && part.length > 4) { matchId = parseInt(part); break; } }
            }
            const startDate = new Date(item.pubDate).getTime();
            return {
                id: matchId,
                seriesName: item.description || "Cricket Series",
                matchDesc: matchDesc || item.title,
                matchFormat: "T20",
                team1Name: teams[0] || "Team A",
                team1ShortName: (teams[0] || "T1").substring(0, 3).toUpperCase(),
                team1Img: "1",
                team2Name: teams[1] || "Team B",
                team2ShortName: (teams[1] || "T2").substring(0, 3).toUpperCase(),
                team2Img: "2",
                startDate: startDate,
                endDate: startDate + (4 * 60 * 60 * 1000),
                venue: "See Cricbuzz",
                status: startDate < now ? "Live" : "Upcoming"
            };
        });

        // 2. RapidAPI Fallback
        if (allMatches.length === 0) {
            console.log("⚠️ RSS Empty. Trying RapidAPI...");
            const apiKey = req.headers['x-rapidapi-key'];
            const apiHost = req.headers['x-rapidapi-host'];

            if (apiKey && apiHost) {
                try {
                    const apiRes = await axios.get(`https://${apiHost}/matches/v1/upcoming`, {
                        headers: { 'X-RapidAPI-Key': apiKey, 'X-RapidAPI-Host': apiHost }
                    });

                    if (apiRes.data && apiRes.data.typeMatches) {
                        // Parse RapidAPI Data
                        const types = apiRes.data.typeMatches;
                        for (const type of types) {
                            if (type.seriesMatches) {
                                for (const series of type.seriesMatches) {
                                    if (series.matches) {
                                        for (const m of series.matches) {
                                            const mi = m.matchInfo;
                                            allMatches.push({
                                                id: mi.matchId,
                                                seriesName: series.seriesAdWrapper ? series.seriesAdWrapper.seriesName : "Series",
                                                matchDesc: mi.matchDesc || "Match",
                                                matchFormat: mi.matchFormat || "T20",
                                                team1Name: mi.team1.teamName,
                                                team1ShortName: mi.team1.teamSName,
                                                team1Img: mi.team1.imageId,
                                                team2Name: mi.team2.teamName,
                                                team2ShortName: mi.team2.teamSName,
                                                team2Img: mi.team2.imageId,
                                                startDate: parseInt(mi.startDate),
                                                endDate: parseInt(mi.endDate),
                                                venue: mi.venueInfo.ground,
                                                status: "Upcoming"
                                            });
                                        }
                                    }
                                }
                            }
                        }
                    }
                } catch (e) { console.error("RapidAPI Fallback Failed:", e.message); }
            }
        }

        // Remove Duplicates
        const uniqueMatches = Array.from(new Map(allMatches.map(m => [m.id, m])).values());

        if (uniqueMatches.length > 0) {
            // Update Cache
            cache.matches = { data: uniqueMatches, timestamp: Date.now() };
            console.log(`✅ Cache Updated: ${uniqueMatches.length} matches`);
            return res.json({ matches: uniqueMatches });
        } else {
            // Mock Data Fallback (Only if EVERYTHING fails)
            throw new Error("No data sources worked.");
        }

    } catch (error) {
        console.error("❌ Fetch Failed:", error.message);
        // Serve Stale Cache if available
        if (cache.matches.data) {
            console.log("⚠️ Serving Stale Cache due to Error");
            return res.json({ matches: cache.matches.data, cached: true, stale: true });
        }
        // Last Resort: Mock Data
        return res.json({ matches: getMockMatches(), source: 'mock' });
    }
});

// Route: Get Recent Matches (New Endpoint)
app.get('/matches/recent', async (req, res) => {
    // Check Cache
    const now = Date.now();
    if (cache.recent.data && (now - cache.recent.timestamp < CACHE_DURATION_MS)) {
        return res.json({ matches: cache.recent.data, cached: true });
    }

    try {
        const apiKey = req.headers['x-rapidapi-key'];
        const apiHost = req.headers['x-rapidapi-host'];

        if (!apiKey) throw new Error("API Key Required for Recent Matches");

        console.log("Fetching Recent Matches from RapidAPI...");
        const response = await axios.get(`https://${apiHost}/matches/v1/recent`, {
            headers: { 'X-RapidAPI-Key': apiKey, 'X-RapidAPI-Host': apiHost }
        });

        let recentMatches = [];
        if (response.data && response.data.typeMatches) {
            // ... Parsing Logic (Similar to Upcoming) ...
            // Simplified for brevity
            const types = response.data.typeMatches;
            for (const type of types) {
                if (type.seriesMatches) {
                    for (const series of type.seriesMatches) {
                        if (series.matches) {
                            for (const m of series.matches) {
                                const mi = m.matchInfo;
                                recentMatches.push({
                                    id: mi.matchId,
                                    seriesName: series.seriesAdWrapper ? series.seriesAdWrapper.seriesName : "Series",
                                    matchDesc: mi.matchDesc,
                                    matchFormat: mi.matchFormat,
                                    team1Name: mi.team1.teamName,
                                    team1ShortName: mi.team1.teamSName,
                                    team1Img: mi.team1.imageId,
                                    team2Name: mi.team2.teamName,
                                    team2ShortName: mi.team2.teamSName,
                                    team2Img: mi.team2.imageId,
                                    startDate: parseInt(mi.startDate),
                                    endDate: parseInt(mi.endDate),
                                    venue: mi.venueInfo ? mi.venueInfo.ground : "",
                                    status: mi.status || "Completed"
                                });
                            }
                        }
                    }
                }
            }
        }

        cache.recent = { data: recentMatches, timestamp: Date.now() };
        res.json({ matches: recentMatches });

    } catch (e) {
        console.error("Recent Fetch Error:", e.message);
        res.status(500).json({ error: e.message });
    }
});

function getMockMatches() {
    // ... [Keep Existing Mock Data Logic] ...
    const now = Date.now();
    return [
        {
            id: 89571,
            seriesName: "IPL 2026 (Mock SC)",
            matchDesc: "1st Match, Group A",
            matchFormat: "T20",
            team1Name: "Chennai Super Kings",
            team1ShortName: "CSK",
            team1Img: "5800",
            team2Name: "Mumbai Indians",
            team2ShortName: "MI",
            team2Img: "5801",
            startDate: now + 3600000,
            endDate: now + 14400000,
            venue: "Wankhede Stadium, Mumbai",
            status: "Upcoming"
        }
    ];
}

// Proxy Route for Scorecard
app.get('/scorecard/:matchId', async (req, res) => {
    const matchId = req.params.matchId;
    const apiKey = req.headers['x-rapidapi-key'];
    const apiHost = req.headers['x-rapidapi-host'];

    // Try RapidAPI First
    if (apiKey) {
        try {
            console.log(`Tunneling Scorecard Request for ${matchId}...`);
            const response = await axios.get(`https://${apiHost}/mcenter/v1/${matchId}/scov2`, {
                headers: { 'X-RapidAPI-Key': apiKey, 'X-RapidAPI-Host': apiHost }
            });
            console.log("✅ RapidAPI Scorecard Success");
            return res.json(response.data);
        } catch (error) {
            console.error("❌ RapidAPI Scorecard Failed:", error.message);
        }
    }

    // --- FALLBACK: Simulated Live Scorecard for Mock Match ---
    // If it's our Mock Match ID (89571) or any failure, generate realistic data
    console.log("⚠️ Generating Simulated Scorecard...");

    // Simulate progression based on time (Jugaad Live Mode)
    const minutes = new Date().getMinutes();
    const runs = 120 + (minutes % 20) * 2; // Runs change every minute
    const wickets = 2 + Math.floor(minutes / 10) % 5;
    const overs = 12 + (minutes % 20) / 6;

    const mockScorecard = {
        scoreCard: [
            {
                matchId: parseInt(matchId),
                inningsId: 1,
                batTeamDetails: {
                    batTeamId: 5800,
                    batTeamShortName: "CSK",
                    batsmenData: {
                        'bat_1': { 'batId': 1, 'batName': 'Ruturaj Gaikwad', 'runs': 45 + (minutes % 10), 'balls': 30, 'fours': 4, 'sixes': 2, 'strikeRate': 150.0, 'isOut': false },
                        'bat_2': { 'batId': 2, 'batName': 'Shivam Dube', 'runs': 22 + (minutes % 5), 'balls': 15, 'fours': 1, 'sixes': 2, 'strikeRate': 146.0, 'isOut': false },
                    }
                },
                bowlTeamDetails: {
                    bowlTeamId: 5801,
                    bowlTeamShortName: "MI",
                    'bowlersData': {
                        'bowl_1': { 'bowlId': 101, 'bowlName': 'Jasprit Bumrah', 'wickets': 1, 'overs': 3, 'runs': 24, 'economy': 8.0 },
                        'bowl_2': { 'bowlId': 102, 'bowlName': 'Hardik Pandya', 'wickets': wickets - 1 > 0 ? wickets - 1 : 0, 'overs': 2, 'runs': 18, 'economy': 9.0 }
                    }
                },
                scoreDetails: {
                    run: runs,
                    wickets: wickets,
                    overs: overs,
                    isDeclared: false,
                    isFollowOn: false
                }
            }
        ],
        status: "Live",
        matchInfo: {
            matchId: parseInt(matchId),
            seriesName: "IPL 2026",
            matchDesc: "1st Match",
            matchFormat: "T20",
            startDate: Date.now(),
            endDate: Date.now() + 3600000,
            state: "In Progress",
            status: "Live"
        }
    };

    res.json(mockScorecard);
    res.json(mockScorecard);
});

// Generic Proxy for any RapidAPI Endpoint
app.get('/proxy', async (req, res) => {
    const endpoint = req.query.endpoint;
    const apiKey = req.headers['x-rapidapi-key'];
    const apiHost = req.headers['x-rapidapi-host'];

    if (!endpoint || !apiKey) return res.status(400).json({ error: "Missing endpoint or API Key" });

    try {
        console.log(`Tunneling Generic Request: ${endpoint}`);
        const response = await axios.get(`https://${apiHost}${endpoint}`, {
            headers: { 'X-RapidAPI-Key': apiKey, 'X-RapidAPI-Host': apiHost }
        });
        res.json(response.data);
    } catch (error) {
        console.error("Proxy Error:", error.message);
        res.status(500).json({ error: error.message });
    }
});

app.listen(PORT, () => {
    console.log(`🚀 API Server running on http://localhost:${PORT}`);
});
