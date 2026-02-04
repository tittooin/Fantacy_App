/**
 * Cricket Engine - Core Logic for Phase 2 (LiveScore6 Migration)
 * Responsibilities:
 * 1. Fetch from Rapids LiveScore6 API
 * 2. Parse Data (Adapted Schema)
 * 3. Update Cloudflare D1 (Delta Updates Only)
 * 4. STRICTLY NO FIRESTORE WRITES
 */

import { calculateFantasyPoints } from './points_engine.js';
import { processPayoutsForMatch } from './payout_engine.js';

export async function processCricketData(env) {
    console.log("🏏 Cricket Engine Started (LiveScore6)...");
    const apiKey = env.RAPID_API_KEY;
    const apiHost = 'livescore6.p.rapidapi.com'; // MIGRATION HOST

    try {
        // 1. Fetch Schedule (includes Live usually)
        const matches = await fetchMatchesFromAPI(apiKey, apiHost, env);
        console.log(`📡 Fetched ${matches.length} matches from API`);

        // 2. Process Matches (Upsert to D1)
        for (const match of matches) {
            await syncMatchToD1(match, env);

            // 3. If Live, Fetch & Update Score (TODO: Update for LS6)
            if (isLive(match.status)) {
                // LS6 Live Score usually needs specific endpoint or is included in List info
                // For now, we rely on List info for basic score, detailed stats disabled temporarily
                // await processLiveScore(match.id, match.matchFormat || 'T20', apiKey, apiHost, env);
            }
            // 4. If Completed, JUST Log it (Payouts are now MANUAL via Admin)
            else if (match.status === 'Completed') {
                console.log(`✅ Match ${match.id} Completed. Waiting for Admin Payout Trigger.`);
            }
        }

        console.log("✅ Cricket Engine Cycle Complete");
        return matches; // Return for API response

    } catch (e) {
        console.error("❌ Cricket Engine Error:", e);
        return [];
    }
}

// --- CORE FUNCTIONS ---

async function syncMatchToD1(match, env) {
    try {
        // Check if exists and changed
        const existing = await env.DB.prepare('SELECT last_updated, status, team_a_id FROM matches WHERE id = ?').bind(match.id).first();

        if (existing) {
            const missingIds = !existing.team_a_id;
            if (!missingIds && existing.status === match.status && match.status !== 'Live' && match.status !== 'In Progress') {
                return;
            }
        }

        // Upsert
        await env.DB.prepare(`
            INSERT INTO matches (id, series_id, title, short_title, status, start_time, team_a, team_b, team_a_img, team_b_img, team_a_id, team_b_id, last_updated)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                status = excluded.status,
                title = excluded.title,
                team_a_id = excluded.team_a_id,
                team_b_id = excluded.team_b_id,
                last_updated = excluded.last_updated
        `).bind(
            match.id, match.seriesId, match.title, match.shortTitle, match.status,
            match.startTime, match.teamA, match.teamB, match.teamAImg, match.teamBImg,
            match.team1Id, match.team2Id,
            Date.now()
        ).run();

    } catch (e) {
        console.error(`Error syncing match ${match.id}:`, e);
    }
}

// --- API HELPERS (LiveScore6 Migration) ---

async function fetchMatchesFromAPI(key, host, env) {
    const primary = {
        host: host,
        endpointLive: '/matches/v2/list-live?Category=cricket',
        endpointDate: '/matches/v2/list-by-date?Category=cricket'
    };

    let parsed = [];

    // 1. Fetch LIVE
    try {
        console.log(`📡 Fetching Live: https://${primary.host}${primary.endpointLive}`);
        const resp = await fetch(`https://${primary.host}${primary.endpointLive}`, {
            headers: { 'x-rapidapi-key': key, 'x-rapidapi-host': primary.host }
        });

        if (resp.ok) {
            const data = await resp.json();
            const liveMatches = parseMatches(data);
            console.log(`✅ Live Matches: ${liveMatches.length}`);
            parsed = [...parsed, ...liveMatches];
        } else {
            console.error(`❌ Live Fetch Error: ${resp.status}`);
        }
    } catch (e) {
        console.error(`⚠️ Live API Failed: ${e.message}`);
    }

    // 2. Fetch UPCOMING (Yesterday, Today, Tomorrow) - Coverage across timezones
    try {
        const dates = [];
        const d = new Date();
        dates.push(d.toISOString().split('T')[0].replace(/-/g, '')); // Today
        d.setDate(d.getDate() + 1);
        dates.push(d.toISOString().split('T')[0].replace(/-/g, '')); // Tomorrow
        d.setDate(d.getDate() - 2);
        dates.push(d.toISOString().split('T')[0].replace(/-/g, '')); // Yesterday

        for (const dateStr of dates) {
            const url = `https://${primary.host}${primary.endpointDate}&Date=${dateStr}`;
            console.log(`📡 Fetching Schedule (${dateStr}): ${url}`);

            const resp = await fetch(url, {
                headers: { 'x-rapidapi-key': key, 'x-rapidapi-host': primary.host }
            });

            if (resp.ok) {
                const data = await resp.json();
                const schedMatches = parseMatches(data);
                console.log(`✅ Scheduled Matches (${dateStr}): ${schedMatches.length}`);
                parsed = [...parsed, ...schedMatches];
            }
        }
    } catch (e) {
        console.error(`⚠️ Schedule API Failed: ${e.message}`);
    }

    if (parsed.length === 0) return [];

    // Deduplicate
    const unique = new Map();
    parsed.forEach(m => {
        if (m.id && m.team1Name && m.team2Name) {
            unique.set(m.id, m);
        }
    });

    console.log(`🔍 Found ${unique.size} unique matches from LiveScore6`);

    // --- SERIES FILTERING ---
    let allowedIds = [];
    try {
        const results = await env.DB.prepare("SELECT series_id FROM allowed_series").all();
        if (results && results.results) {
            allowedIds = results.results.map(r => r.series_id.toString());
        }
    } catch (e) {
        console.error("⚠️ Failed allowed_series fetch", e);
    }

    const finalMatches = Array.from(unique.values());

    if (allowedIds.length > 0) {
        console.log(`🎯 Filtering for Allowed Series: ${allowedIds.join(', ')}`);
        return finalMatches.filter(m => allowedIds.includes(m.seriesId?.toString()));
    } else {
        return finalMatches;
    }
}

function parseMatches(data) {
    let matches = [];
    if (data.Stages && Array.isArray(data.Stages)) {
        data.Stages.forEach(stage => {
            const events = stage.Events || [];
            events.forEach(event => {
                const m = formatMatch(event, stage);
                if (m) matches.push(m);
            });
        });
    }
    return matches;
}

function parseLiveScoreDate(dateStr) {
    // Format: YYYYMMDDHHMMSS e.g. 20260203203000
    if (!dateStr) return Date.now();
    const str = dateStr.toString();
    if (str.length < 14) return Date.now();
    const y = str.substring(0, 4);
    const m = str.substring(4, 6);
    const d = str.substring(6, 8);
    const h = str.substring(8, 10);
    const min = str.substring(10, 12);
    const s = str.substring(12, 14);
    // Assume UTC as per standard API practice
    return new Date(`${y}-${m}-${d}T${h}:${min}:${s}Z`).getTime();
}

function formatMatch(event, stage) {
    if (!event || !event.T1 || !event.T2) return null;
    const t1 = event.T1[0] || {};
    const t2 = event.T2[0] || {};
    const mId = event.Eid;
    const sDate = parseLiveScoreDate(event.Esd);

    if (!mId || !t1.Nm || !t2.Nm) return null;

    let status = 'Upcoming';
    const statusText = event.EpsL || '';
    if (statusText === 'Finished' || statusText === 'Full Time' || statusText.includes('Result')) status = 'Completed';
    else if (statusText === 'Play in progress' || statusText === 'Innings Break') status = 'Live';
    else if (statusText === 'Cancelled' || statusText === 'Abandoned') status = 'Abandoned';

    if (status === 'Upcoming' && Date.now() > sDate + 3600000) status = 'Live'; // Fallback

    return {
        id: mId.toString(), // MAPPED: Eid -> id
        seriesId: (stage.Sid || '0').toString(), // MAPPED: Sid -> seriesId
        seriesName: stage.Snm || stage.Cnm || 'Unknown Series',
        title: `${t1.Nm} vs ${t2.Nm}`, // MAPPED: Constructed
        shortTitle: `${t1.Abr || t1.Nm.substring(0, 3)} vs ${t2.Abr || t2.Nm.substring(0, 3)}`,
        status: status, // MAPPED: Derived
        startTime: sDate, // MAPPED: Esd -> timestamp
        teamA: t1.Nm, // T1.Nm
        teamB: t2.Nm, // T2.Nm
        teamAImg: t1.Img || '',
        teamBImg: t2.Img || '',
        team1Id: (t1.ID || '0').toString(), // MAPPED: T1.ID
        team2Id: (t2.ID || '0').toString(), // MAPPED: T2.ID
        matchFormat: stage.Ccd ? stage.Ccd.toUpperCase() : 'T20',
        lastUpdated: Date.now()
    };
}

function isLive(status) {
    return status === 'Live' || status === 'In Progress';
}
