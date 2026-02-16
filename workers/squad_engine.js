/**
 * Squad Engine v2 (Quota Safe - State Machine)
 * STRICT RULES:
 * 1. Max 2 API hits per match lifetime
 * 2. State 0 -> 1 (Initial Fetch)
 * 3. State 1 -> 2 (Final Fetch @ Live + 10 mins)
 * 4. Never overwrite with empty data
 */

export async function processSquads(env) {
    const logs = [];
    logs.push("👥 Squad Engine v2 (State Machine) Started...");
    const apiKey = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee'; // New Key
    const apiHost = 'cricbuzz-cricket.p.rapidapi.com'; // New Host

    try {
        const now = Date.now();
        const tenMins = 10 * 60 * 1000;

        // 1. Select Candidates based on STATE & TIME
        const query = `
            SELECT m.id, m.series_id, m.status, m.start_time, 
                   COALESCE(s.squad_state, 0) as current_state
            FROM matches m
            LEFT JOIN match_squads s ON m.id = s.match_id
            WHERE 
                (COALESCE(s.squad_state, 0) = 0 AND (m.status = 'Upcoming' OR m.status = 'Live'))
                OR
                (
                    s.squad_state = 1 
                    AND m.status = 'Live' 
                    AND (? > (m.start_time + ?))
                )
        `;

        const { results: matches } = await env.DB.prepare(query).bind(now, tenMins).all();

        if (!matches || matches.length === 0) {
            logs.push("✅ No matches need squad sync.");
            return { processed: 0, logs };
        }

        logs.push(`Processing ${matches.length} matches for Squad Sync...`);

        for (const match of matches) {
            const state = match.current_state;
            logs.push(`🔄 Syncing ${match.id} | State: ${state} -> Target: ${state === 0 ? 1 : 2}`);

            // 2. FETCH (New API)
            const data = await fetchSquadSafe(match.id, match.series_id, apiKey, apiHost, env);

            // 3. DETERMINE TARGET STATE
            let newState = 1;
            if (state === 1) newState = 2; // Lock forever

            logs.push(`  -> Data Valid: ${!!data} | New State: ${newState}`);

            // 4. SAVE
            await saveToDB(env, String(match.id), data, newState);
        }

        return { processed: matches.length, logs };

    } catch (e) {
        logs.push("ERROR: " + e.message);
        console.error("Squad Engine Error:", e);
        return { processed: 0, error: e.message, logs };
    }
}

// --- CORE SAVE LOGIC ---

async function saveToDB(env, matchId, data, newState) {
    const now = Date.now();

    if (data && isValid(data)) {
        console.log(`✅ Valid Data for ${matchId}. Saving & Advancing State to ${newState}.`);
        // FULL UPDATE
        await env.DB.prepare(`
            INSERT INTO match_squads (match_id, team_a_roster, team_b_roster, playing_11_a, playing_11_b, squad_state, last_updated)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(match_id) DO UPDATE SET
                squad_state = excluded.squad_state,
                last_updated = excluded.last_updated,
                team_a_roster = excluded.team_a_roster,
                team_b_roster = excluded.team_b_roster
        `).bind(
            matchId,
            JSON.stringify(data.teamA),
            JSON.stringify(data.teamB),
            JSON.stringify([]), // XI not supported in this API yet
            JSON.stringify([]),
            newState,
            now
        ).run();
    } else {
        console.log(`⚠️ Empty/Failed Data for ${matchId}. Advancing State to ${newState} ONLY. Preserving Old Data.`);
        // STATE ADVANCE ONLY (No Data Overwrite)
        // If row doesn't exist, insert empty + state. Using '[]' for empty is safer than NULL for frontend.
        await env.DB.prepare(`
             INSERT INTO match_squads (match_id, team_a_roster, team_b_roster, playing_11_a, playing_11_b, squad_state, last_updated)
             VALUES (?, '[]', '[]', '[]', '[]', ?, ?)
             ON CONFLICT(match_id) DO UPDATE SET
                squad_state = excluded.squad_state,
                last_updated = excluded.last_updated
                -- STRICTLY NO ROSTER UPDATE HERE
        `).bind(matchId, newState, now).run();
    }
}

function isValid(data) {
    if (!data) return false;
    if (!data.teamA || !data.teamB) return false;
    return (data.teamA.length > 0 || data.teamB.length > 0);
}

// --- NEW API ADAPTER (cricbuzz-cricket) ---

// ... (Top Half Unchanged)

// --- NEW API ADAPTER (cricbuzz-cricket) ---

async function fetchSquadSafe(matchId, seriesId, key, host, env) {
    try {
        // Get Team Names from DB
        const matchInfo = await env.DB.prepare("SELECT team_a, team_b, team_a_id, team_b_id FROM matches WHERE id = ?").bind(matchId).first();
        if (!matchInfo) return null;

        const teamA = matchInfo.team_a || 'Team A';
        const teamB = matchInfo.team_b || 'Team B';
        const teamAId = matchInfo.team_a_id || '0';
        const teamBId = matchInfo.team_b_id || '0';

        // Fetch Series Squads
        if (!seriesId || seriesId == '0') return null;

        const url = `https://${host}/series/v1/${seriesId}/squads`;
        const resp = await fetch(url, { headers: { 'x-rapidapi-key': key, 'x-rapidapi-host': host } });
        if (!resp.ok) return null;
        const sData = await resp.json();
        if (!sData.squads) return null;

        // Find Squad IDs
        const squadA = findSquad(sData.squads, teamA);
        const squadB = findSquad(sData.squads, teamB);

        const result = { teamA: [], teamB: [] };

        if (squadA) result.teamA = await fetchPlayers(squadA, seriesId, key, host, teamAId, 'T1');
        if (squadB) result.teamB = await fetchPlayers(squadB, seriesId, key, host, teamBId, 'T2');

        return result;

    } catch (e) {
        console.error(`API Adapter Error ${matchId}:`, e);
        return null;
    }
}

function findSquad(squads, teamName) {
    if (!squads || !teamName) return null;
    const nameLower = teamName.toLowerCase();
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
    } catch (e) { }
    return [];
}

function mapPlayers(players, teamId, shortName) {
    return players.map(p => ({
        id: (p.id || '').toString(),
        name: p.name || 'Unknown',
        role: normalizeRoleStrict(p.role), // STRICT NORMALIZATION
        imageUrl: p.imageId ? `https://static.cricbuzz.com/a/img/v1/i1/c${p.imageId}/i.jpg` : '',
        isCaptain: p.captain || false,
        isWicketKeeper: false, // Deprecated, rely on role
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
export async function syncMatchSquad(env, match, key, host) {
    // This function is now legacy. The new processSquads handles everything.
    // Use this only if manually triggered, but route it through safe fetching logic.
    return null;
}


