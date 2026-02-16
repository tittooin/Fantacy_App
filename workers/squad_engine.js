/**
 * Squad Engine v2 (Quota Safe - State Machine)
 * STRICT RULES:
 * 1. Max 2 API hits per match lifetime
 * 2. State 0 -> 1 (Initial Fetch)
 * 3. State 1 -> 2 (Final Fetch @ Live + 10 mins)
 * 4. Never overwrite with empty data
 */

// --- SERIES WHITELIST (API SAVER) ---
function isPrioritySeries(seriesName) {
    if (!seriesName) return false;
    const s = seriesName.toUpperCase();

    // International Tournaments
    if (s.includes('WORLD CUP')) return true;
    if (s.includes('T20 WORLD CUP')) return true;
    if (s.includes('CHAMPIONS TROPHY')) return true;
    if (s.includes('ASIA CUP')) return true;

    // Franchise Leagues (Major only)
    if (s.includes('IPL') || s.includes('INDIAN PREMIER')) return true;
    if (s.includes('PSL') || s.includes('PAKISTAN SUPER')) return true;
    if (s.includes('BBL') || s.includes('BIG BASH')) return true;
    if (s.includes('THE HUNDRED')) return true;

    // Add Women's equivalents if needed, currently generic matching covers most.
    if (s.includes('WPL') || s.includes('WOMEN\'S PREMIER')) return true;

    return false;
}

export async function processSquads(env) {
    const logs = [];
    logs.push("👥 Squad Engine V2 (State-Based Safe Mode) Started...");
    const apiKey = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
    const apiHost = 'cricbuzz-cricket.p.rapidapi.com';

    try {
        const now = Date.now();
        const thirtyMins = 30 * 60 * 1000;
        const fortyEightHours = 48 * 60 * 60 * 1000;

        // 1. Select Candidates based on STATE & TIME
        const query = `
            SELECT m.id, m.series_id, m.status, m.start_time, m.title,
                   COALESCE(s.squad_state, 0) as current_state
            FROM matches m
            LEFT JOIN match_squads s ON m.id = s.match_id
            WHERE 
                (
                    -- PHASE 1: Pre-Match (State 0 -> 1)
                    COALESCE(s.squad_state, 0) = 0 
                    AND (m.status = 'Upcoming')
                    AND (m.start_time - ? <= ?) -- Inside 48h
                )
                OR
                (
                    -- PHASE 2: Toss/Live (State 1 -> 2)
                    COALESCE(s.squad_state, 0) = 1 
                    AND (
                        m.status = 'Live' 
                        OR (m.status = 'Upcoming' AND (? >= m.start_time - ?)) -- Within 30 mins of start
                    )
                )
        `;

        const { results: matches } = await env.DB.prepare(query).bind(now, fortyEightHours, now, thirtyMins).all();

        if (!matches || matches.length === 0) {
            logs.push("✅ No matches need squad sync.");
            return { processed: 0, logs };
        }

        logs.push(`Processing ${matches.length} matches for Squad Sync...`);

        for (const match of matches) {
            // WHITELIST CHECK
            if (!isPrioritySeries(match.title)) {
                logs.push(`⏭️ Skipping ${match.id} (${match.title}): Not in Whitelist.`);
                continue;
            }

            const state = match.current_state;
            let targetState = state;
            let source = 'NONE';

            // DETERMINE TRANSITION
            if (state === 0) {
                targetState = 1;
                source = 'SERIES';
            } else if (state === 1) {
                targetState = 2;
                source = 'SCARD';
            }

            logs.push(`🔄 Syncing ${match.id} | State: ${state} -> Target: ${targetState} | Source: ${source}`);

            if (source === 'NONE') continue;

            // 2. FETCH DIRECTLY BY SOURCE
            const data = await fetchSquadBySource(match.id, match.series_id, source, apiKey, apiHost, env);

            // 3. SAVE (Pass Source to handle Merge logic)
            await saveToDB(env, String(match.id), data, targetState, source);

            logs.push(`  -> Processed ${source}. Result: ${data && !data.error ? 'Success' : 'Failed'}`);
        }

        return { processed: matches.length, logs };

    } catch (e) {
        logs.push("ERROR: " + e.message);
        console.error("Squad Engine Error:", e);
        return { processed: 0, error: e.message, logs };
    }
}

// --- CORE SAVE LOGIC ---

async function saveToDB(env, matchId, data, newState, source) {
    const now = Date.now();

    // VALIDATION
    if (!data || data.error) {
        console.log(`⚠️ Failed Data for ${matchId} (${source}). Skipping Update.`);
        return; // Safety: Do not update state if fetch failed. Retry next time.
    }

    if (source === 'SERIES') {
        // FULL OVERWRITE (State 0 -> 1)
        if (!data.teamA || !data.teamB || data.teamA.length === 0) {
            console.log(`⚠️ Empty Roster for ${matchId}. Skipping Save.`);
            return;
        }

        console.log(`✅ Saving Full Roster for ${matchId}. State -> ${newState}.`);
        await env.DB.prepare(`
            INSERT INTO match_squads (match_id, series_id, team_a_roster, team_b_roster, playing_11_a, playing_11_b, squad_state, last_updated)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(match_id) DO UPDATE SET
                squad_state = excluded.squad_state,
                last_updated = excluded.last_updated,
                team_a_roster = excluded.team_a_roster,
                team_b_roster = excluded.team_b_roster,
                series_id = excluded.series_id
        `).bind(
            matchId,
            data.seriesId,
            JSON.stringify(data.teamA),
            JSON.stringify(data.teamB),
            JSON.stringify([]),
            JSON.stringify([]),
            newState,
            now
        ).run();
    }
    else if (source === 'SCARD') {
        // PARTIAL UPDATE (State 1 -> 2) requires Reading Old + Merging
        // We need to mark players as "is_playing: true" in the roster

        console.log(`✅ Updating Playing XI for ${matchId}. State -> ${newState}.`);

        // 1. Get Current Roster
        const current = await env.DB.prepare("SELECT team_a_roster, team_b_roster FROM match_squads WHERE match_id = ?").bind(matchId).first();
        if (!current) {
            console.log(`⚠️ No existing roster for ${matchId}. Cannot process SCARD update.`);
            return;
        }

        let rosterA = JSON.parse(current.team_a_roster || '[]');
        let rosterB = JSON.parse(current.team_b_roster || '[]');

        const xiA = data.xiA || [];
        const xiB = data.xiB || [];
        const benchA = data.benchA || []; // Use to add if missing? User said "Same squad rahegi". 
        // User rule: "Same squad rahegi + sirf is_playing flag update hoga"
        // Implicitly implies: Do not add players if they are not in original roster? 
        // Or if they are in SCARD but not in Series Squad, should we add them?
        // Safe approach: Update existing. If SCARD has new player, maybe add? 
        // Let's strictly UPDATE flags for now.

        // Helper to update
        const updateRoster = (roster, xiList) => {
            return roster.map(p => ({
                ...p,
                is_playing: xiList.includes(p.id)
            }));
        };

        rosterA = updateRoster(rosterA, xiA);
        rosterB = updateRoster(rosterB, xiB);

        await env.DB.prepare(`
            UPDATE match_squads 
            SET squad_state = ?, last_updated = ?, 
                team_a_roster = ?, team_b_roster = ?,
                playing_11_a = ?, playing_11_b = ?
            WHERE match_id = ?
        `).bind(
            newState,
            now,
            JSON.stringify(rosterA),
            JSON.stringify(rosterB),
            JSON.stringify(xiA),
            JSON.stringify(xiB),
            matchId
        ).run();
    }
}

// --- NEW API ADAPTER (cricbuzz-cricket) ---

// ... (Top Half Unchanged)

// --- NEW API ADAPTER (cricbuzz-cricket) ---



async function fetchSquadSafe(matchId, seriesId, key, host, env) {
    try {
        // Get Team Names from DB
        const matchInfo = await env.DB.prepare("SELECT team_a, team_b, team_a_id, team_b_id FROM matches WHERE id = ?").bind(matchId).first();
        if (!matchInfo) return { error: "Match not found in DB" };

        const teamA = matchInfo.team_a || 'Team A';
        const teamB = matchInfo.team_b || 'Team B';
        const teamAId = matchInfo.team_a_id || '0';
        const teamBId = matchInfo.team_b_id || '0';

        // Fetch Series Squads
        if (!seriesId || seriesId == '0') return { error: "Invalid Series ID" };

        // FORENSIC LOGGING
        const debug = {
            request: {
                seriesId_value: seriesId,
                seriesId_type: typeof seriesId,
                matchId_value: matchId,
                matchId_type: typeof matchId,
                url: `https://${host}/series/v1/${seriesId}/squads`,
                headers_host: host,
                headers_key_len: key ? key.length : 0
            }
        };

        const url = `https://${host}/series/v1/${seriesId}/squads`;
        const resp = await fetch(url, { headers: { 'x-rapidapi-key': key, 'x-rapidapi-host': host } });

        debug.response = {
            status: resp.status,
            statusText: resp.statusText
        };

        const rawText = await resp.text();
        debug.response.body_preview = rawText.substring(0, 500); // First 500 chars

        if (!resp.ok) return { error: `API Error: ${resp.status}`, debug: debug };

        let sData;
        try {
            sData = JSON.parse(rawText);
        } catch (e) {
            return { error: "JSON Parse Error", debug: debug };
        }

        if (!sData.squads) return { error: "No 'squads' in API response", raw: sData, debug: debug };

        // Find Squad IDs
        const squadA = findSquad(sData.squads, teamA);
        const squadB = findSquad(sData.squads, teamB);

        if (!squadA && !squadB) return {
            error: `Squads not found for ${teamA} or ${teamB}`,
            available: sData.squads.map(s => s.squadType || s.teamName),
            debug: debug
        };

        const result = { teamA: [], teamB: [] };

        if (squadA) result.teamA = await fetchPlayers(squadA, seriesId, key, host, teamAId, 'T1');
        else result.debugA = "Squad A missing";

        if (squadB) result.teamB = await fetchPlayers(squadB, seriesId, key, host, teamBId, 'T2');
        else result.debugB = "Squad B missing";

        result.debug = debug; // Include debug in success too
        return result;

    } catch (e) {
        console.error(`API Adapter Error ${matchId}:`, e);
        return { error: `Adapter Exception: ${e.message}` };
    }
}

function isValid(data) {
    if (!data) return false;
    if (!data.teamA || !data.teamB) return false;
    return (data.teamA.length > 0 || data.teamB.length > 0);
}

// --- API ADAPTER ---

async function fetchSquadBySource(matchId, seriesId, source, key, host, env) {
    try {
        if (source === 'SERIES') {
            return await fetchSeriesSquads(matchId, seriesId, key, host, env);
        } else if (source === 'SCARD') {
            return await fetchMatchScard(matchId, key, host);
        }
        return { error: "Unknown Source" };
    } catch (e) {
        console.error(`Adapter Error ${matchId} (${source}):`, e);
        return { error: e.message };
    }
}

async function fetchSeriesSquads(matchId, seriesId, key, host, env) {
    // Get Team Names from DB for Mapping
    const matchInfo = await env.DB.prepare("SELECT team_a, team_b, team_a_id, team_b_id FROM matches WHERE id = ?").bind(matchId).first();
    if (!matchInfo) return { error: "Match not found in DB" };

    const teamA = matchInfo.team_a;
    const teamB = matchInfo.team_b;
    const teamAId = matchInfo.team_a_id || '0';
    const teamBId = matchInfo.team_b_id || '0';

    if (!seriesId || seriesId == '0') return { error: "Invalid Series ID" };

    const url = `https://${host}/series/v1/${seriesId}/squads`;
    const resp = await fetch(url, { headers: { 'x-rapidapi-key': key, 'x-rapidapi-host': host } });
    if (!resp.ok) return { error: `API Error: ${resp.status} ${resp.statusText}` };

    const sData = await resp.json();
    if (!sData.squads) return { error: "No 'squads' in API response" };

    const squadA = findSquad(sData.squads, teamA);
    const squadB = findSquad(sData.squads, teamB);

    if (!squadA && !squadB) return { error: `Squads not found for ${teamA} or ${teamB}` };

    const result = { teamA: [], teamB: [], seriesId };

    if (squadA) result.teamA = await fetchPlayers(squadA, seriesId, key, host, teamAId, 'T1');
    if (squadB) result.teamB = await fetchPlayers(squadB, seriesId, key, host, teamBId, 'T2');

    return result;
}

async function fetchMatchScard(matchId, key, host) {
    const url = `https://${host}/mcenter/v1/${matchId}/scard`;
    const resp = await fetch(url, { headers: { 'x-rapidapi-key': key, 'x-rapidapi-host': host } });

    if (!resp.ok) return { error: `Scard Error: ${resp.status}` };
    const data = await resp.json();

    if (!data.miniScore) return { error: "No miniScore in Scard" };

    const tA = data.miniScore.teamA || {};
    const tB = data.miniScore.teamB || {};

    // Extract IDs only
    const getIDs = (list) => (list || []).map(p => p.id).filter(id => !!id).map(String);

    return {
        xiA: getIDs(tA.playingXI),
        benchA: getIDs(tA.bench),
        xiB: getIDs(tB.playingXI),
        benchB: getIDs(tB.bench)
    };
}

// --- HELPER FUNCTIONS ---

function findSquad(squads, teamName) {
    if (!squads || !teamName) return null;
    const nameLower = teamName.toLowerCase();
    // Prioritize direct match
    let found = squads.find(s => !s.isHeader && s.squadType && nameLower === s.squadType.toLowerCase());
    if (found) return found;

    // Fallback to inclusion
    return squads.find(s => !s.isHeader && s.squadType && nameLower.includes(s.squadType.toLowerCase()))
        || squads.find(s => !s.isHeader && s.teamName && nameLower.includes(s.teamName.toLowerCase()));
}

async function fetchPlayers(squad, seriesId, key, host, teamId, shortName) {
    if (!squad || !squad.squadId) return [];

    try {
        const url = `https://${host}/series/v1/${seriesId}/squads/${squad.squadId}`;
        const resp = await fetch(url, { headers: { 'x-rapidapi-key': key, 'x-rapidapi-host': host } });

        if (resp.ok) {
            const data = await resp.json();
            if (data.player) return mapPlayers(data.player, teamId, shortName);
        }
    } catch (e) { console.error("Player Fetch Error", e); }
    return [];
}

function mapPlayers(players, teamId, shortName) {
    return players
        .filter(p => p.id && p.name && !p.isHeader) // VALIDATION FILTER
        .map(p => ({
            id: (p.id || '').toString(),
            name: p.name || 'Unknown',
            role: normalizeRoleStrict(p.role),
            imageUrl: p.imageId ? `https://static.cricbuzz.com/a/img/v1/i1/c${p.imageId}/i.jpg` : '',
            isCaptain: p.captain || false,
            isWicketKeeper: false,
            is_playing: false, // Default for Pre-Match
            teamId: teamId.toString(),
            teamShortName: shortName
        }));
}

function normalizeRoleStrict(role) {
    if (!role) return 'BAT';
    const r = role.toUpperCase();
    if (r.includes('WK') || r.includes('KEEPER')) return 'WK';
    if (r.includes('ALL') || r.includes('ROUND')) return 'AR';
    if (r.includes('BOWL')) return 'BOWL';
    return 'BAT';
}

// Deprecated Entry Point (Kept for compatibility if other files import it, but effectively redirects)
// Manual Entry Point (Updated to support Sources)
export async function syncMatchSquad(matchId, env, sourceOverride) {
    console.log(`🛠️ Manual Sync Requested for ${matchId} [${sourceOverride || 'AUTO'}]`);
    const apiKey = env.RAPID_API_KEY || '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
    const apiHost = 'cricbuzz-cricket.p.rapidapi.com';

    // 1. Get Match Info
    const match = await env.DB.prepare("SELECT id, series_id, status FROM matches WHERE id = ?").bind(matchId).first();
    if (!match) return { error: "Match Not Found" };

    // 2. Determine Source
    let source = sourceOverride;
    let targetState = 0;

    if (!source) {
        // Auto-Detect logic (Simplified for manual tool)
        source = 'SERIES';
        targetState = 1;
        if (match.status === 'Live') {
            source = 'SCARD';
            targetState = 2;
        }
    } else {
        targetState = source === 'SERIES' ? 1 : 2;
    }

    // 3. Fetch
    const data = await fetchSquadBySource(match.id, match.series_id, source, apiKey, apiHost, env);

    // 4. Save
    await saveToDB(env, String(matchId), data, targetState, source);

    return { data, source, targetState };
}
