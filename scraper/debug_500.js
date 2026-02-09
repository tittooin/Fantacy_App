
// Simulation of Worker Environment
const env = {
    RAPID_API_KEY: 'TEST_KEY',
    RAPID_API_HOST: 'test.rapidapi.com',
    DB: {
        prepare: (query) => {
            console.log("SQL Prepare:", query);
            return {
                bind: (...args) => {
                    console.log("SQL Bind:", args);
                    return {
                        first: async () => {
                            if (query.includes("matches WHERE id")) {
                                // Simulate MISSING series_id case first
                                // return { team_a_id: 10, team_b_id: 20 }; 
                                // Simulate PRESENT series_id case
                                return { team_a_id: 10, team_b_id: 20, series_id: 79900 };
                            }
                            if (query.includes("match_squads")) {
                                return null; // Cache miss
                            }
                            return null;
                        },
                        run: async () => { console.log("SQL Run"); return {}; }
                    };
                }
            };
        }
    }
};

// Mock Fetch
global.fetch = async (url, options) => {
    console.log("FETCH:", url);
    // Simulate API Response logic
    if (url.includes("/squads/139029")) {
        // Return 204 or valid data?
        // Let's return valid data to test parsing
        return {
            ok: true,
            status: 200,
            json: async () => ({
                items: [
                    { players: [{ id: 1, name: "Player A", role: "Batsman" }] },
                    { players: [{ id: 2, name: "Player B", role: "Bowler" }] }
                ]
            })
        };
    }
    return { ok: false, status: 404 };
};

// --- LOGIC FROM index.js & squad_engine.js ---

async function handleGetSquads(matchId, env) {
    try {
        console.log("--- START handleGetSquads ---");
        if (!matchId) throw new Error('matchId required');

        // 1. D1 cache read (Mocked to null)
        const d1Squad = await env.DB.prepare(
            "SELECT team_a_roster, team_b_roster, playing_11_a, playing_11_b, last_updated FROM match_squads WHERE match_id = ?"
        ).bind(matchId).first();

        // Fetch Team IDs & Series ID from matches table
        let matchInfo;
        try {
            matchInfo = await env.DB.prepare("SELECT team_a_id, team_b_id, series_id FROM matches WHERE id = ?").bind(matchId).first();
        } catch (e) {
            console.error("SQL Error fetching series_id, falling back to basic query:", e);
            matchInfo = await env.DB.prepare("SELECT team_a_id, team_b_id FROM matches WHERE id = ?").bind(matchId).first();
        }

        const team1Id = matchInfo?.team_a_id || 0;
        const team2Id = matchInfo?.team_b_id || 0;
        const seriesId = matchInfo?.series_id || 0;

        console.log("Resolved Series ID:", seriesId);

        // 3. Lazy fetch
        console.log(`🔄 Squad stale/missing for ${matchId} (Series ${seriesId}), fetching...`);
        const mockMatch = { id: matchId, status: 'Upcoming', series_id: seriesId };

        await syncMatchSquad(env, mockMatch, env.RAPID_API_KEY, env.RAPID_API_HOST);

        console.log("--- END handleGetSquads ---");
        return { success: true };

    } catch (e) {
        console.error('Squad Error CRASH:', e);
        return { success: false, error: e.message };
    }
}

async function syncMatchSquad(env, match, key, host) {
    const matchId = match.id;
    const seriesId = match.series_id || match.seriesId || '0';
    let finalSquads = { teamA: [], teamB: [], xiA: [], xiB: [] };

    try {
        console.log(`📡 Syncing Squad for Match ${matchId} (Series ${seriesId})`);

        // Fetch Match Detail First to get Team IDs
        const matchDetail = await env.DB.prepare("SELECT team_a, team_b, team_a_id, team_b_id FROM matches WHERE id = ?").bind(matchId).first();
        // Since we mock prepare, this will return the same as above logic for matches table

        if (!matchDetail) {
            // In mock we might need to handle this if query string diff matches
            console.log("MatchDetail not found (Mock limitation?)");
            // Let's assume it returns something because our mock keys solely on "matches WHERE id"
        }

        const apiHost = host;
        const matchSquadUrl = `https://${apiHost}/series/v1/${seriesId}/squads/${matchId}`;

        console.log("Fetching URL:", matchSquadUrl);
        let resp = await fetch(matchSquadUrl, {
            headers: {
                'x-rapidapi-key': key,
                'x-rapidapi-host': apiHost
            }
        });

        if (resp.ok && resp.status !== 204) {
            const data = await resp.json();
            console.log("Got Data:", JSON.stringify(data).substring(0, 50));
        }

        // Mock DB Save
        console.log("Saving to DB...");
        // await env.DB.prepare(...).run() // Mocked

    } catch (e) {
        console.error(`Failed squad sync for ${matchId}:`, e);
        // Rethrow to verify if it bubbles? No, code says return null.
        return null;
    }
}

// RUN
handleGetSquads(139029, env);
