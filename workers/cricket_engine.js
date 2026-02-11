/**
 * Cricket Engine - Core Logic for Match Fetching (Cricbuzz Migration)
 * Responsibilities:
 * 1. Fetch from Cricbuzz Cricket API (RapidAPI)
 * 2. Parse Data (Cricbuzz Structure)
 * 3. Update Cloudflare D1 (Delta Updates Only)
 * 4. STRICTLY NO FIRESTORE WRITES
 */

import { calculateFantasyPoints } from './points_engine.js';
// import { processPayoutsForMatch } from './payout_engine.js'; // Disabled for now

export async function processCricketData(env) {
    console.log("🏏 Cricket Engine Started (Cricbuzz)...");
    const apiKey = env.RAPID_API_KEY;
    const apiHost = 'cricbuzz-cricket.p.rapidapi.com';

    try {
        // Fetch Matches (Live, Upcoming, Recent)
        // 3 Hits per cycle. If cycle is 10 mins = ~13k hits/month. Safe.
        const matches = await fetchMatchesFromAPI(apiKey, apiHost, env);
        console.log(`📡 Fetched ${matches.length} matches from API`);

        // Process Matches (Upsert to D1)
        for (const match of matches) {
            await syncMatchToD1(match, env);
        }

        // Return Latest State from D1 (Always full list) with Frontend Compatibility
        const cached = await env.DB.prepare('SELECT * FROM matches ORDER BY start_time ASC').all();

        const mappedResults = cached.results.map(m => ({
            ...m,
            // Map D1 snake_case to Frontend expected keys
            team1Name: m.team_a,
            team2Name: m.team_b,
            teamA: m.team_a,
            teamB: m.team_b,
            matchDesc: m.title,
            seriesName: m.series_name || m.title, // Use DB Series Name, Fallback to Title
            team1ShortName: m.short_title ? m.short_title.split(' vs ')[0] : (m.team_a ? m.team_a.substring(0, 3).toUpperCase() : 'T1'),
            team2ShortName: m.short_title ? m.short_title.split(' vs ')[1] : (m.team_b ? m.team_b.substring(0, 3).toUpperCase() : 'T2'),
            team1Id: m.team_a_id,
            team2Id: m.team_b_id,
            startDate: m.start_time,
            status: m.status
        }));

        console.log(`✅ Returns ${mappedResults.length} matches from D1 (Mapped)`);
        return mappedResults;

    } catch (e) {
        console.error("❌ Cricket Engine Error:", e);
        // Fallback: Try to list DB anyway
        try {
            const cached = await env.DB.prepare('SELECT * FROM matches ORDER BY start_time ASC').all();
            return cached.results.map(m => ({
                ...m,
                team1Name: m.team_a,
                team2Name: m.team_b,
                teamA: m.team_a,
                teamB: m.team_b,
                matchDesc: m.title,
                startDate: m.start_time
            }));
        } catch (ex) { return []; }
    }
}

// --- CORE FUNCTIONS ---

async function syncMatchToD1(match, env) {
    try {
        // Check if exists and changed
        const existing = await env.DB.prepare('SELECT last_updated, status, team_a_id FROM matches WHERE id = ?').bind(match.id).first();

        if (existing) {
            const existingStatus = existing.status;

            await env.DB.prepare(`
                UPDATE matches SET 
                title = ?,
                short_title = ?,
                series_id = ?,
                series_name = ?,
                start_time = ?,
                status = ?,
                team_a_img = ?,
                team_b_img = ?,
                team_a_id = ?,
                team_b_id = ?,
                last_updated = ?
                WHERE id = ?
            `).bind(
                match.title, match.shortTitle, match.seriesId, match.seriesName || '', match.startTime, match.status,
                match.teamAImg, match.teamBImg, match.team1Id, match.team2Id, Date.now(), match.id
            ).run();

        } else {
            await env.DB.prepare(`
            INSERT INTO matches (id, series_id, series_name, title, short_title, status, start_time, team_a, team_b, team_a_img, team_b_img, team_a_id, team_b_id, last_updated)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            `).bind(
                match.id, match.seriesId, match.seriesName || '', match.title, match.shortTitle, match.status, match.startTime,
                match.teamA, match.teamB, match.teamAImg, match.teamBImg, match.team1Id, match.team2Id, Date.now()
            ).run();
            // Trigger Squad Fetch for New Match
            if (match.status === 'Upcoming' || match.status === 'Live') {
                const squadCheck = await env.DB.prepare(`SELECT match_id FROM match_squads WHERE match_id = ?`).bind(match.id).first();
                if (!squadCheck) {
                    console.log(`🆕 New match detected: ${match.id}, queuing squad check...`);
                    const { syncMatchSquad } = await import('./squad_engine.js');
                    await syncMatchSquad(env, { id: match.id, series_id: match.seriesId, status: match.status }, env.RAPID_API_KEY, env.RAPID_API_HOST);
                }
            }
        }

    } catch (e) {
        console.error(`Error syncing match ${match.id}:`, e);
    }
}

// --- API HELPERS (Cricbuzz Migration) ---

async function fetchMatchesFromAPI(key, host, env) {
    let parsed = [];
    const endpoints = [
        { path: '/matches/v1/live', key: 'fetch_live', ttl: 300000 },      // 5 Mins
        { path: '/matches/v1/upcoming', key: 'fetch_upcoming', ttl: 900000 }, // 15 Mins
        { path: '/matches/v1/recent', key: 'fetch_recent', ttl: 1800000 }   // 30 Mins
    ];

    for (const ep of endpoints) {
        try {
            // Throttling Check per Endpoint
            const dbKey = `last_${ep.key}`;
            const lastFetch = await env.DB.prepare("SELECT value FROM sys_config WHERE key = ?").bind(dbKey).first();

            if (lastFetch && (Date.now() - parseInt(lastFetch.value)) < ep.ttl) {
                console.log(`⏳ Skipping ${ep.path} (Limit < ${ep.ttl / 60000}m)`);
                continue;
            }

            // Execute Fetch
            const url = `https://${host}${ep.path}`;
            console.log(`📡 Fetching: ${url}`);
            const resp = await fetch(url, {
                headers: {
                    'x-rapidapi-key': key,
                    'x-rapidapi-host': host,
                    'User-Agent': 'Mozilla/5.0'
                }
            });

            if (resp.ok) {
                const data = await resp.json();
                const matches = parseCricbuzzMatches(data);
                console.log(`✅ ${ep.path}: Found ${matches.length} matches`);
                parsed = [...parsed, ...matches];

                // Update Timestamp ONLY on success
                await env.DB.prepare("INSERT OR REPLACE INTO sys_config (key, value, updated_at) VALUES (?, ?, ?)").bind(dbKey, Date.now().toString(), Date.now()).run();

            } else {
                console.error(`⚠️ API Error ${ep.path}: ${resp.status}`);
            }
        } catch (e) {
            console.error(`Fetch Failed ${ep.path}:`, e);
        }
    }

    if (parsed.length === 0) return [];

    // Deduplicate by ID
    const unique = new Map();
    parsed.forEach(m => {
        if (m.id) unique.set(m.id, m);
    });

    return Array.from(unique.values());
}

function parseCricbuzzMatches(data) {
    let matches = [];
    // Structure: typeMatches[] -> seriesMatches[] -> seriesAdWrapper -> matches[] -> matchInfo
    if (data.typeMatches && Array.isArray(data.typeMatches)) {
        data.typeMatches.forEach(tm => {
            if (tm.seriesMatches) {
                tm.seriesMatches.forEach(sm => {
                    const wrapper = sm.seriesAdWrapper || {};
                    if (wrapper.matches) {
                        wrapper.matches.forEach(m => {
                            const parsed = formatCricbuzzMatch(m.matchInfo);
                            if (parsed) matches.push(parsed);
                        });
                    }
                });
            }
        });
    }
    return matches;
}

function formatCricbuzzMatch(info) {
    if (!info || !info.matchId) return null;

    // Status Mapping
    let status = 'Upcoming';
    const state = info.state || ''; // Complete, In Progress, Preview, Toss, Stumps...

    if (state === 'Complete' || state === 'Mom' || state.includes('Won')) status = 'Completed';
    else if (state === 'In Progress' || state === 'Live' || state === 'Toss' || state === 'Stumps' || state === 'Innings Break') status = 'Live';
    else if (state === 'Preview' || state === 'Upcoming') status = 'Upcoming';
    else if (state === 'Abandoned' || state === 'No Result') status = 'Abandoned';

    // Teams
    const t1 = info.team1 || {};
    const t2 = info.team2 || {};

    return {
        id: info.matchId.toString(),
        seriesId: (info.seriesId || '0').toString(),
        seriesName: info.seriesName || 'Unknown Series',
        title: `${t1.teamName || 'T1'} vs ${t2.teamName || 'T2'}`,
        shortTitle: `${t1.teamSName || 'T1'} vs ${t2.teamSName || 'T2'}`,
        status: status,
        matchFormat: info.matchFormat ? info.matchFormat.toUpperCase() : 'T20',

        // COMPATIBILITY FIELDS (For Frontend)
        team1Name: t1.teamName || 'Team A',
        team2Name: t2.teamName || 'Team B',
        team1ShortName: t1.teamSName || 'T1',
        team2ShortName: t2.teamSName || 'T2',
        matchDesc: `${t1.teamName} vs ${t2.teamName}`,
        startDate: parseInt(info.startDate) || Date.now(),
        endDate: parseInt(info.endDate) || (parseInt(info.startDate) + 14400000), // Fallback +4h
        venue: info.venueInfo ? info.venueInfo.ground : 'TBD',

        startTime: parseInt(info.startDate) || Date.now(), // Ensure MS

        teamA: t1.teamName || 'Team A',
        teamB: t2.teamName || 'Team B',
        teamAImg: t1.imageId ? `https://static.cricbuzz.com/a/img/v1/i1/c${t1.imageId}/i.jpg` : '',
        teamBImg: t2.imageId ? `https://static.cricbuzz.com/a/img/v1/i1/c${t2.imageId}/i.jpg` : '',

        team1Id: (t1.teamId || '0').toString(),
        team2Id: (t2.teamId || '0').toString(),

        lastUpdated: Date.now()
    };
}

