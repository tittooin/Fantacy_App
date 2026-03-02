/**
 * Cricket Engine - PREDICTIVE GUARDED VERIFICATION MODE (< 25 Calls/Match)
 * Responsibilities:
 * 1. Fetch from Cricbuzz Cricket API (RapidAPI)
 * 2. Parse Data (Cricbuzz Structure)
 * 3. Update Cloudflare D1 (Delta Updates Only) — Informational Stats Only
 * 4. STRICTLY NO FIRESTORE WRITES
 *
 * STRATEGIC GUARDRAIL:
 * // cricket_engine.js - Social Interaction Rooms Processor (Non-monetary)
 * No competitive wagering, gambling semantics, or platform-led payouts are permitted.
 * Future categories must be reviewed for social interaction compliance before implementation.
 */

import { isPrioritySeries } from './squad_engine.js'; // Shared Whitelist
// import { processPayoutsForMatch } from './payout_engine.js'; // Disabled for now

// --- EMERGENCY API LOCK (STEP 1) ---
// Sab external API calls band hain. Sirf DB se data return hoga.
// Jab stable ho jaye, is flag ko false karo.
const API_LOCK_ACTIVE = false; // CONTROLLED UNLOCK — D1 atomic lock active
const STALE_LIVE_RECONCILE_ENABLED = true; // Feature flag for safe rollback
const STALE_LIVE_MISS_THRESHOLD = 5; // Close after 5 consecutive misses
const STALE_LIVE_GRACE_ARM_AT = 4; // Arm grace one cycle before close
const UPCOMING_EMPTY_CHECK_KEY = 'upcoming_empty_checked_at';
const UPCOMING_EMPTY_CHECK_COOLDOWN_MS = 6 * 60 * 60 * 1000;
const PREDICTIVE_CHECK_COOLDOWN_MS = 5 * 60 * 1000;
const LIVE_SNAPSHOT_HASH_KEY = 'live_snapshot_hash';
const LIVE_SNAPSHOT_SKIP_WINDOW_MS = 60 * 60 * 1000;
const UPCOMING_SNAPSHOT_HASH_KEY = 'upcoming_snapshot_hash';
const UPCOMING_SNAPSHOT_SKIP_WINDOW_MS = 4 * 60 * 60 * 1000;
const MATCH_STATE_CLASS_PREFIX = 'match_state_class:';
const TERMINAL_COMPLETED_TOKENS = ['won', 'beat', 'defeated', 'result', 'match over', 'innings win'];
const TERMINAL_ABANDONED_TOKENS = ['abandoned', 'no result', 'cancelled', 'match abandoned'];
const NON_TERMINAL_STATE_TOKENS = ['rain', 'delay', 'delayed', 'wet outfield', 'inspection', 'toss delayed', 'start delayed', 'bad light', 'interruption'];

// --- PREDICTIVE GUARDED VERIFICATION (Target < 25 Calls) ---

export async function processCricketData(env) {
    console.log("🏏 Cricket Engine Shuru (Predictive Guarded Verification Mode)...");

    // STEP 1: SCHEMA VERIFY (Safe Mode - sirf missing columns add karo)
    await verifySchema(env);

    // STEP 2: API LOCK CHECK
    if (API_LOCK_ACTIVE) {
        console.log("[API_LOCK_ACTIVE] Sab external API calls band hain. Sirf DB se data return ho raha hai.");
        // Sirf DB se return karo, koi fetch nahi
        return await getMatchesFromDB(env);
    }

    try {
        // Fetch Logic using Custom Zero-Cost Scraper
        const matches = await fetchPublicLiveMatches(env);

        if (matches && matches.length > 0) {
            console.log(`📡 Scraper se ${matches.length} matches mila`);

            // CONTROLLED UNLOCK: LIMIT 1 match sync per cron
            for (const match of matches.slice(0, 1)) {
                console.log('[CONTROL_UNLOCK_MATCH_ID] Syncing: ' + match.id);
                await syncMatchToD1(match, env);
            }
        }

        return await getMatchesFromDB(env);

    } catch (e) {
        console.error("❌ Cricket Engine Error:", e);
        return await getMatchesFromDB(env);
    }
}


export async function seedUpcomingMatches(env) {
    const nowMs = Date.now();
    const windowEndMs = nowMs + (48 * 60 * 60 * 1000);
    const dbUpcomingRows = await env.DB.prepare(`
        SELECT id, start_time
        FROM matches
        WHERE status = 'Upcoming'
        AND start_time IS NOT NULL
        AND CAST(start_time AS INTEGER) > ?
    `).bind(nowMs).all();

    const currentUpcomingHash = buildUpcomingSnapshotHash(dbUpcomingRows.results || []);
    const upcomingSnapshotState = parseSnapshotState(
        await readSysConfigValue(env, UPCOMING_SNAPSHOT_HASH_KEY)
    );
    if (
        upcomingSnapshotState &&
        upcomingSnapshotState.hash &&
        upcomingSnapshotState.hash === currentUpcomingHash &&
        upcomingSnapshotState.stableUntil > nowMs
    ) {
        return;
    }

    const countRow = await env.DB.prepare(`
        SELECT COUNT(1) AS upcoming_count
        FROM matches
        WHERE status = 'Upcoming'
        AND start_time IS NOT NULL
        AND CAST(start_time AS INTEGER) > ?
        AND CAST(start_time AS INTEGER) < ?
    `).bind(nowMs, windowEndMs).first();

    const upcomingCount = Number(countRow?.upcoming_count || 0);
    if (upcomingCount >= 15) {
        console.log(`[UPCOMING_SEED_SKIP] ${upcomingCount} matches already available in next 48h.`);
        return;
    }


    const lastEmptyCheckedAt = await readSysConfigTimestamp(env, UPCOMING_EMPTY_CHECK_KEY);
    if (lastEmptyCheckedAt > 0 && (nowMs - lastEmptyCheckedAt) < UPCOMING_EMPTY_CHECK_COOLDOWN_MS) {
        console.log('[UPCOMING_SEED_SKIP] Empty window cooldown active.');
        return;
    }

    const incomingMatches = await fetchPublicLiveMatches(env); // Fallback to live scraper for upcoming if needed
    if (!Array.isArray(incomingMatches) || incomingMatches.length === 0) {
        await writeSysConfigTimestamp(env, UPCOMING_EMPTY_CHECK_KEY, nowMs);
        const emptyHash = buildUpcomingSnapshotHash([]);
        const stableUntil = (upcomingSnapshotState?.hash === emptyHash)
            ? nowMs + UPCOMING_SNAPSHOT_SKIP_WINDOW_MS
            : 0;
        await writeSysConfigValue(env, UPCOMING_SNAPSHOT_HASH_KEY, JSON.stringify({
            hash: emptyHash,
            stableUntil
        }));
        console.log('[UPCOMING_SEED_NO_DATA] Scraper returned no upcoming matches.');
        return;
    }

    let inserted = 0;
    let updated = 0;

    for (const match of incomingMatches) {
        const matchId = String(match?.id || '').trim();
        const startTime = Number(match?.startTime || 0);

        if (!matchId || startTime <= nowMs) {
            continue;
        }

        const existing = await env.DB.prepare(`
            SELECT status, start_time
            FROM matches
            WHERE id = ?
        `).bind(matchId).first();

        if (!existing) {
            await env.DB.prepare(`
                INSERT INTO matches(
            id,
            series_id,
            series_name,
            title,
            short_title,
            status,
            start_time,
            team_a,
            team_b,
            team_a_img,
            team_b_img,
            team_a_id,
            team_b_id,
            last_updated,
            last_score,
            last_wickets,
            last_over,
            last_innings
        ) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).bind(
                matchId,
                match.seriesId || '0',
                match.seriesName || '',
                match.title || '',
                match.shortTitle || '',
                'Upcoming',
                startTime,
                match.teamA || '',
                match.teamB || '',
                match.teamAImg || '',
                match.teamBImg || '',
                match.team1Id || '0',
                match.team2Id || '0',
                startTime,
                match.lastScore || null,
                match.lastWickets || 0,
                match.lastOver || null,
                match.lastInnings || 1
            ).run();
            inserted += 1;
            continue;
        }

        if (existing.status !== 'Upcoming') {
            continue;
        }

        const existingStart = Number(existing.start_time || 0);
        if (existingStart === startTime) {
            continue;
        }

        await env.DB.prepare(`
            UPDATE matches
            SET start_time = ?, last_updated = ?
        WHERE id = ?
            AND status = 'Upcoming'
                `).bind(startTime, startTime, matchId).run();
        updated += 1;
    }

    if (inserted === 0) {
        await writeSysConfigTimestamp(env, UPCOMING_EMPTY_CHECK_KEY, nowMs);
    } else {
        await clearSysConfigTimestamp(env, UPCOMING_EMPTY_CHECK_KEY);
    }

    const incomingUpcomingHash = buildUpcomingSnapshotHash(incomingMatches);
    const upcomingStableUntil = (upcomingSnapshotState?.hash === incomingUpcomingHash)
        ? nowMs + UPCOMING_SNAPSHOT_SKIP_WINDOW_MS
        : 0;
    await writeSysConfigValue(env, UPCOMING_SNAPSHOT_HASH_KEY, JSON.stringify({
        hash: incomingUpcomingHash,
        stableUntil: upcomingStableUntil
    }));

    console.log(`[UPCOMING_SEED_DONE] inserted = ${inserted}, updated = ${updated}, scanned = ${incomingMatches.length}`);
}

export async function warmupMissingUpcomingSquads(env) {
    const nowMs = Date.now();

    const eligibleRows = await env.DB.prepare(`
        SELECT m.id
        FROM matches m
        LEFT JOIN match_squads ms
            ON CAST(ms.match_id AS INTEGER) = CAST(m.id AS INTEGER)
        LEFT JOIN sys_config sc
            ON sc.key = ('squad_warmup_done:' || CAST(m.id AS TEXT))
        WHERE m.status = 'Upcoming'
        AND m.start_time IS NOT NULL
        AND CAST(m.start_time AS INTEGER) > ?
        AND ms.match_id IS NULL
        AND sc.key IS NULL
        ORDER BY CAST(m.start_time AS INTEGER) ASC
        LIMIT 2
        `).bind(nowMs).all();

    const matches = eligibleRows.results || [];
    if (matches.length === 0) {
        console.log('[SQUAD_WARMUP_SKIP] No eligible upcoming matches.');
        return;
    }

    const { syncMatchSquad } = await import('./squad_engine.js');

    let attempted = 0;
    let success = 0;
    let failed = 0;

    for (const row of matches) {
        const matchId = String(row?.id || '').trim();
        if (!matchId) continue;

        const markerKey = `squad_warmup_done: ${matchId}`;
        const claimAt = Date.now();

        const claim = await env.DB.prepare(
            "INSERT OR IGNORE INTO sys_config (key, value, updated_at) VALUES (?, ?, ?)"
        ).bind(
            markerKey,
            JSON.stringify({ status: 'claimed', claimedAt: claimAt }),
            claimAt
        ).run();

        if (!claim.meta || claim.meta.changes !== 1) {
            continue;
        }

        attempted += 1;

        const marker = {
            status: 'failed',
            source: 'SERIES',
            reason: 'UNKNOWN',
            attemptedAt: claimAt
        };

        try {
            const result = await syncMatchSquad(matchId, env, 'SERIES');
            const errorText = result?.error || result?.data?.error;

            if (errorText) {
                marker.reason = String(errorText);
                failed += 1;
            } else {
                marker.status = 'success';
                marker.reason = 'OK';
                success += 1;
            }
        } catch (e) {
            marker.reason = e?.message ? String(e.message) : 'EXCEPTION';
            failed += 1;
        }

        marker.attemptedAt = Date.now();
        await env.DB.prepare(
            "UPDATE sys_config SET value = ?, updated_at = ? WHERE key = ?"
        ).bind(
            JSON.stringify(marker),
            marker.attemptedAt,
            markerKey
        ).run();
    }

    console.log(`[SQUAD_WARMUP_DONE] attempted = ${attempted}, success = ${success}, failed = ${failed}, scanned = ${matches.length}`);
}


// --- SCHEMA VERIFY (STEP 2) ---
// Sirf missing columns add karta hai. Existing data safe rahega.
async function verifySchema(env) {
    try {
        // matches table columns check
        const matchesCols = ['last_score', 'last_wickets', 'last_over', 'last_innings'];
        for (const col of matchesCols) {
            try {
                await env.DB.prepare(`SELECT ${col} FROM matches LIMIT 1`).first();
                // Column exists
            } catch (e) {
                // Column missing - add karo
                const colDef = col === 'last_score' ? 'TEXT' :
                    col === 'last_over' ? 'TEXT' :
                        col === 'last_wickets' ? 'INTEGER' :
                            col === 'last_innings' ? 'INTEGER' : 'TEXT';
                await env.DB.prepare(`ALTER TABLE matches ADD COLUMN ${col} ${colDef}`).run();
                console.log(`[SCHEMA_COLUMN_ADDED] ${col} column add kiya gaya matches table mein`);
            }
        }

        // leaderboards table verify (read-only check, no ALTER)
        try {
            await env.DB.prepare(`SELECT total_points FROM leaderboards LIMIT 1`).first();
            console.log(`[SCHEMA_OK] leaderboards.total_points column exist karta hai.`);
        } catch (e) {
            // Non-critical: sirf log karo, crash nahi karna
            console.log(`[SCHEMA_SKIP] leaderboards check fail(non - critical): ${e.message}`);
        }

        console.log("[SCHEMA_OK] Schema verify complete.");
    } catch (e) {
        console.error("[SCHEMA_VERIFY_ERROR] Schema check fail:", e.message);
        // Schema fail pe crash nahi karna
    }
}

// --- DB SE MATCHES RETURN (Helper) ---
async function getMatchesFromDB(env) {
    try {
        const cached = await env.DB.prepare('SELECT * FROM matches ORDER BY start_time ASC').all();
        return (cached.results || []).map(m => ({
            ...m,
            team1Name: m.team_a,
            team2Name: m.team_b,
            teamA: m.team_a,
            teamB: m.team_b,
            matchDesc: m.title,
            seriesName: m.series_name || m.title,
            team1ShortName: m.short_title ? m.short_title.split(' vs ')[0] : (m.team_a ? m.team_a.substring(0, 3).toUpperCase() : 'T1'),
            team2ShortName: m.short_title ? m.short_title.split(' vs ')[1] : (m.team_b ? m.team_b.substring(0, 3).toUpperCase() : 'T2'),
            team1Id: m.team_a_id,
            team2Id: m.team_b_id,
            startDate: m.start_time,
            status: m.status,
            lastScore: m.last_score,
            lastWickets: m.last_wickets,
            lastOver: m.last_over,
            lastInnings: m.last_innings
        }));
    } catch (ex) {
        console.error("[DB_READ_ERROR] Matches DB se nahi aaya:", ex.message);
        return [];
    }
}

// --- CORE FUNCTIONS ---

// DB write fail hone par match polling 30 min ke liye block hogi
const DB_WRITE_FAIL_BLOCK = new Map(); // matchId -> failTime (in-memory, per worker instance)

async function syncMatchToD1(match, env) {
    // STEP 3: DB WRITE FAIL GUARD
    const failTime = DB_WRITE_FAIL_BLOCK.get(match.id);
    if (failTime) {
        const elapsed = Date.now() - failTime;
        if (elapsed < 30 * 60 * 1000) { // 30 minute block
            console.log(`[DB_WRITE_FAIL_GUARD ${match.id}]DB write fail ke baad 30 min block chal raha hai(${Math.floor(elapsed / 60000)}m elapsed).Skip.`);
            return;
        } else {
            DB_WRITE_FAIL_BLOCK.delete(match.id); // Block expire, reset karo
        }
    }

    try {
        // Check if exists
        const existing = await env.DB.prepare('SELECT last_updated, status, team_a_id FROM matches WHERE id = ?').bind(match.id).first();

        // Always update last_updated to reset the predictive guard timer
        const now = Date.now();

        if (existing) {
            await env.DB.prepare(`
                UPDATE matches SET 
                title = ?,
        short_title = ?,
        series_id = ?,
        series_name = ?,
        start_time = ?,
        status = ?,
        team_a = ?,
        team_b = ?,
        team_a_img = ?,
        team_b_img = ?,
        team_a_id = ?,
        team_b_id = ?,
        last_updated = ?,
        last_score = ?,
        last_wickets = ?,
        last_over = ?,
        last_innings = ?
            WHERE id = ?
                `).bind(
                match.title, match.shortTitle, match.seriesId, match.seriesName || '', match.startTime, match.status,
                match.teamA, match.teamB,
                match.teamAImg, match.teamBImg, match.team1Id, match.team2Id, now,
                match.lastScore || null, match.lastWickets || 0, match.lastOver || null, match.lastInnings || 1,
                match.id
            ).run();

        } else {
            await env.DB.prepare(`
            INSERT INTO matches(id, series_id, series_name, title, short_title, status, start_time, team_a, team_b, team_a_img, team_b_img, team_a_id, team_b_id, last_updated, last_score, last_wickets, last_over, last_innings)
            VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            `).bind(
                match.id, match.seriesId, match.seriesName || '', match.title, match.shortTitle, match.status, match.startTime,
                match.teamA, match.teamB, match.teamAImg, match.teamBImg, match.team1Id, match.team2Id, now,
                match.lastScore || null, match.lastWickets || 0, match.lastOver || null, match.lastInnings || 1
            ).run();
            // Trigger Squad Fetch for New Match
            if (match.status === 'Upcoming' || match.status === 'Live') {
                const squadCheck = await env.DB.prepare(`SELECT match_id FROM match_squads WHERE match_id = ? `).bind(match.id).first();
                if (!squadCheck) {
                    console.log(`🆕 Naya match mila: ${match.id}, squad check queue mein...`);
                    const { syncMatchSquad } = await import('./squad_engine.js');
                    await syncMatchSquad(env, { id: match.id, series_id: match.seriesId, status: match.status }, env.RAPID_API_KEY, env.RAPID_API_HOST);
                }
            }
        }

        if (match.stateClass) {
            await writeMatchStateClass(env, match.id, match.stateClass);
        }

    } catch (e) {
        // DB write fail guard activate karo
        DB_WRITE_FAIL_BLOCK.set(match.id, Date.now());
        console.error(`[DB_WRITE_FAIL_GUARD ${match.id}]DB write fail hua. 30 min ke liye polling block.Error: ${e.message}`);
    }
}

// --- API HELPERS (Predictive Guard Logic) ---

// Helper for Updating DB Timestamp Global
async function updateDBTimestamp(env, key) {
    const now = Date.now().toString();
    await env.DB.prepare("INSERT OR REPLACE INTO sys_config (key, value, updated_at) VALUES (?, ?, ?)").bind(key, now, Date.now()).run();
}

async function readSysConfigTimestamp(env, key) {
    const row = await env.DB.prepare("SELECT value FROM sys_config WHERE key = ?").bind(key).first();
    if (!row || row.value === null || row.value === undefined) return 0;
    const ts = Number(row.value);
    return Number.isFinite(ts) ? ts : 0;
}

async function writeSysConfigTimestamp(env, key, timestamp) {
    const ts = Number(timestamp || 0);
    await env.DB.prepare(
        "INSERT OR REPLACE INTO sys_config (key, value, updated_at) VALUES (?, ?, ?)"
    ).bind(key, String(ts), Date.now()).run();
}

async function clearSysConfigTimestamp(env, key) {
    await env.DB.prepare("DELETE FROM sys_config WHERE key = ?").bind(key).run();
}

async function readSysConfigValue(env, key) {
    const row = await env.DB.prepare("SELECT value FROM sys_config WHERE key = ?").bind(key).first();
    return row?.value ?? null;
}

async function writeSysConfigValue(env, key, value) {
    await env.DB.prepare(
        "INSERT OR REPLACE INTO sys_config (key, value, updated_at) VALUES (?, ?, ?)"
    ).bind(key, String(value ?? ''), Date.now()).run();
}

function stableHash(input) {
    const text = String(input || '');
    let hash = 2166136261;
    for (let i = 0; i < text.length; i += 1) {
        hash ^= text.charCodeAt(i);
        hash = Math.imul(hash, 16777619);
    }
    return (hash >>> 0).toString(16).padStart(8, '0');
}

function normalizeSnapshotInt(value) {
    const num = Number(value || 0);
    return Number.isFinite(num) ? num : 0;
}

function buildUpcomingSnapshotHash(matches) {
    const rows = (Array.isArray(matches) ? matches : [])
        .map((m) => {
            const matchId = String(m?.id ?? '').trim();
            const startTime = normalizeSnapshotInt(m?.startTime ?? m?.start_time);
            return `${matchId} | ${startTime}`;
        })
        .filter(Boolean)
        .sort();
    return stableHash(rows.join('||'));
}

function buildLiveSnapshotHash(matches) {
    const rows = (Array.isArray(matches) ? matches : [])
        .map((m) => {
            const matchId = String(m?.id ?? '').trim();
            const status = String(m?.status ?? '').trim();
            const lastUpdated = normalizeSnapshotInt(m?.lastUpdated ?? m?.last_updated);
            return `${matchId} | ${status} | ${lastUpdated}`;
        })
        .filter(Boolean)
        .sort();
    return stableHash(rows.join('||'));
}

function parseSnapshotState(rawValue) {
    if (!rawValue) return null;
    try {
        const parsed = JSON.parse(rawValue);
        if (!parsed || typeof parsed !== 'object') return null;
        const hash = String(parsed.hash || '').trim();
        const stableUntil = normalizeSnapshotInt(parsed.stableUntil);
        return { hash, stableUntil };
    } catch {
        return null;
    }
}

function buildMatchStateClassKey(matchId) {
    return `${MATCH_STATE_CLASS_PREFIX}${String(matchId)}`;
}

async function readMatchStateClass(env, matchId) {
    const key = buildMatchStateClassKey(matchId);
    const row = await env.DB.prepare("SELECT value FROM sys_config WHERE key = ?").bind(key).first();
    return String(row?.value || '').trim();
}

async function writeMatchStateClass(env, matchId, stateClass) {
    const key = buildMatchStateClassKey(matchId);
    await env.DB.prepare(
        "INSERT OR REPLACE INTO sys_config (key, value, updated_at) VALUES (?, ?, ?)"
    ).bind(key, String(stateClass || ''), Date.now()).run();
}

function normalizeStateText(value) {
    return String(value || '').trim().toLowerCase();
}

function hasAnyToken(text, tokens) {
    return tokens.some(token => text.includes(token));
}

function classifyMatchStateClass(stateText, statusText) {
    const haystack = `${normalizeStateText(stateText)} ${normalizeStateText(statusText)}`.trim();
    if (!haystack) return 'UNKNOWN';
    if (hasAnyToken(haystack, TERMINAL_ABANDONED_TOKENS)) return 'TERMINAL_ABANDONED';
    if (hasAnyToken(haystack, TERMINAL_COMPLETED_TOKENS)) return 'TERMINAL_COMPLETED';
    if (hasAnyToken(haystack, NON_TERMINAL_STATE_TOKENS)) return 'NON_TERMINAL';
    return 'UNKNOWN';
}

function deriveNonTerminalStatus(startTimeMs, nowMs) {
    return startTimeMs > nowMs ? 'Upcoming' : 'Live';
}

function isTerminalDbStatus(status) {
    const normalized = String(status || '').trim();
    return normalized === 'Completed' || normalized === 'Finished' || normalized === 'Abandoned';
}

async function persistLiveStateClasses(env, liveApiMatches) {
    if (!Array.isArray(liveApiMatches) || liveApiMatches.length === 0) return;
    const writes = [];
    for (const match of liveApiMatches) {
        const matchId = String(match?.id || '').trim();
        const stateClass = String(match?.stateClass || '').trim();
        if (!matchId || !stateClass) continue;
        writes.push(writeMatchStateClass(env, matchId, stateClass));
    }
    if (writes.length > 0) {
        await Promise.all(writes);
    }
}

async function restoreTerminalStatusesFromNonTerminalApi(env, liveApiMatches, nowMs) {
    if (!Array.isArray(liveApiMatches) || liveApiMatches.length === 0) return;
    for (const match of liveApiMatches) {
        const matchId = String(match?.id || '').trim();
        if (!matchId) continue;
        if (String(match?.stateClass || '') !== 'NON_TERMINAL') continue;

        const restoredStatus = deriveNonTerminalStatus(normalizeSnapshotInt(match?.startTime), nowMs);
        await env.DB.prepare(`
            UPDATE matches
            SET status = ?, last_updated = ?
        WHERE id = ?
            AND status IN('Completed', 'Finished', 'Abandoned')
        `).bind(restoredStatus, nowMs, matchId).run();
    }
}

function buildPredictiveCheckedKey(matchId) {
    return `predictive_checked: ${String(matchId)}`;
}

function normalizeSnapshotValue(value) {
    if (value === null || value === undefined) return '';
    return String(value);
}

function isPredictiveStateUnchanged(dbMatch, apiMatch) {
    if (!dbMatch) return false;

    // Upcoming candidate that still doesn't appear in /live is treated as unchanged.
    if (!apiMatch) {
        return String(dbMatch.status || '') === 'Upcoming';
    }

    const dbStatus = normalizeSnapshotValue(dbMatch.status);
    const apiStatus = normalizeSnapshotValue(apiMatch.status);
    if (dbStatus !== apiStatus) return false;

    const dbScore = normalizeSnapshotValue(dbMatch.last_score);
    const apiScore = normalizeSnapshotValue(apiMatch.lastScore);
    const dbWickets = Number(dbMatch.last_wickets || 0);
    const apiWickets = Number(apiMatch.lastWickets || 0);
    const dbOver = normalizeSnapshotValue(dbMatch.last_over);
    const apiOver = normalizeSnapshotValue(apiMatch.lastOver);
    const dbInnings = Number(dbMatch.last_innings || 0);
    const apiInnings = Number(apiMatch.lastInnings || 0);

    return dbScore === apiScore &&
        dbWickets === apiWickets &&
        dbOver === apiOver &&
        dbInnings === apiInnings;
}

function buildStaleLiveKey(matchId) {
    return `stale_live: ${String(matchId)}`;
}

async function readStaleLiveTracker(env, key) {
    const row = await env.DB.prepare("SELECT value FROM sys_config WHERE key = ?").bind(key).first();
    if (!row || !row.value) return null;

    try {
        const parsed = JSON.parse(row.value);
        return (parsed && typeof parsed === 'object') ? parsed : null;
    } catch {
        return null;
    }
}

async function writeStaleLiveTracker(env, key, payload) {
    await env.DB.prepare(
        "INSERT OR REPLACE INTO sys_config (key, value, updated_at) VALUES (?, ?, ?)"
    ).bind(key, JSON.stringify(payload), Date.now()).run();
}

async function clearStaleLiveTracker(env, key) {
    await env.DB.prepare("DELETE FROM sys_config WHERE key = ?").bind(key).run();
}


async function selfHealStaleUpcomingMatches(env, nowMs) {
    const SIX_HOURS = 6 * 60 * 60 * 1000;

    // Recently started upcoming matches are moved to in-progress state.
    await env.DB.prepare(`
        UPDATE matches
        SET status = 'In Progress', last_updated = ?
        WHERE status = 'Upcoming'
        AND start_time IS NOT NULL
        AND CAST(start_time AS INTEGER) > 0
        AND CAST(start_time AS INTEGER) < ?
        AND CAST(start_time AS INTEGER) >= ?
        `).bind(nowMs, nowMs, nowMs - SIX_HOURS).run();

    // Very old upcoming matches are considered completed for UI self-heal.
    await env.DB.prepare(`
        UPDATE matches
        SET status = 'Completed', last_updated = ?
        WHERE status = 'Upcoming'
        AND start_time IS NOT NULL
        AND CAST(start_time AS INTEGER) > 0
        AND CAST(start_time AS INTEGER) < ?
        `).bind(nowMs, nowMs - SIX_HOURS).run();
}

async function reconcileStaleLiveMatches(env, liveApiMatches, nowMs) {
    if (STALE_LIVE_RECONCILE_ENABLED !== true) return;
    if (!Array.isArray(liveApiMatches)) return;

    const dbLive = await env.DB.prepare(`
        SELECT id, status, start_time, last_updated
        FROM matches
        WHERE status IN('Live', 'In Progress', 'Innings Break')
        `).all();

    const dbLiveMatches = dbLive.results || [];
    if (dbLiveMatches.length === 0) return;

    for (const match of dbLiveMatches) {
        const matchId = String(match.id ?? '').trim();
        if (!matchId) continue;

        const trackerKey = buildStaleLiveKey(matchId);
        const stateClass = await readMatchStateClass(env, matchId);

        if (stateClass === 'NON_TERMINAL') {
            console.log(`[RECONCILE_BLOCKED_NON_TERMINAL] matchId = ${matchId}`);
            await clearStaleLiveTracker(env, trackerKey);
            continue;
        }

        const closeAllowedByStateAuthority =
            stateClass === 'TERMINAL_COMPLETED' ||
            stateClass === 'TERMINAL_ABANDONED';

        if (!closeAllowedByStateAuthority) {
            await clearStaleLiveTracker(env, trackerKey);
            continue;
        }

        const terminalStatus = stateClass === 'TERMINAL_ABANDONED' ? 'Abandoned' : 'Completed';
        await env.DB.prepare(`
            UPDATE matches
            SET status = ?, last_updated = ?
        WHERE id = ?
            AND status IN('Live', 'In Progress', 'Innings Break')
        `).bind(terminalStatus, nowMs, match.id).run();

        await clearStaleLiveTracker(env, trackerKey);
    }
}

// Helper for Fetching
async function fetchEndpoint(path, key, host) {
    try {
        const url = `https://${host}${path}`;
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
            console.log(`✅ ${path}: Found ${matches.length} matches`);
            return matches;
        } else {
            console.error(`⚠️ API Error ${path}: ${resp.status}`);
            return null;
        }
    } catch (e) {
        console.error(`Fetch Failed ${path}:`, e);
        return null;
    }
}

async function fetchMatchesWithPredictiveGuard(key, host, env) {
    let parsed = [];
    const now = Date.now();
    const FIVE_MINUTES = 5 * 60 * 1000;
    try {
        await selfHealStaleUpcomingMatches(env, now);
    } catch (_) {
        // Keep predictive guard flow unchanged if self-heal fails.
    }

    // --- RULE A: DB mein live match nahi -> 0 API calls ---
    const activeMatches = await env.DB.prepare(`
        SELECT id, status, start_time, last_updated, last_score, last_wickets, last_over, last_innings
        FROM matches
        WHERE status IN ('Live', 'In Progress', 'Innings Break', 'Upcoming')
    `).all();

    const liveMatches = activeMatches.results.filter(
        m => ['Live', 'In Progress', 'Innings Break'].includes(m.status)
    );
    const upcomingMatches = activeMatches.results.filter(m => m.status === 'Upcoming');
    const liveSnapshotState = parseSnapshotState(
        await readSysConfigValue(env, LIVE_SNAPSHOT_HASH_KEY)
    );

    if (liveMatches.length === 0) {
        // Only allow if an upcoming match has just started (time reached)
        const startingMatch = upcomingMatches.find(m => now >= m.start_time);
        if (!startingMatch) {
            console.log('[CONTROL_UNLOCK_SKIP] DB mein koi live match nahi. 0 API calls.');
            return [];
        }
    }

    if (
        liveSnapshotState &&
        liveSnapshotState.stableUntil > now &&
        liveSnapshotState.hash
    ) {
        return [];
    }

    // --- RULE B: Atomic D1 lock ? race condition proof ---
    // Ensure row exists (first-run safe ? INSERT OR IGNORE)
    await env.DB.prepare(
        "INSERT OR IGNORE INTO sys_config (key, value, updated_at) VALUES ('last_live_api_call', '0', 0)"
    ).run();

    // Atomic conditional UPDATE ? SQLite serializes writes, sirf 1 worker win karega
    const lockResult = await env.DB.prepare(
        `UPDATE sys_config
         SET value = ?, updated_at = ?
         WHERE key = 'last_live_api_call'
         AND (value IS NULL OR CAST(value AS INTEGER) < ?)`
    ).bind(now.toString(), now, now - FIVE_MINUTES).run();

    if (!lockResult.meta || lockResult.meta.changes !== 1) {
        // Lock already held by another worker or within 5-min window
        const lockRow = await env.DB.prepare(
            "SELECT value FROM sys_config WHERE key = 'last_live_api_call'"
        ).first();
        const remainSec = lockRow
            ? Math.ceil((FIVE_MINUTES - (now - parseInt(lockRow.value || '0'))) / 1000)
            : 0;
        console.log(`[CONTROL_UNLOCK_AUTORELOCK] D1 lock active. ~${remainSec}s remaining. 0 API calls.`);
        return [];
    }

    // --- RULE C: Predictive 12-min window check ---
    const dueMatches = liveMatches.filter(m => {
        const lastFetch = m.last_updated || 0;
        return now >= (lastFetch + 12 * 60 * 1000);
    });

    const predictiveCandidates = [];
    for (const match of dueMatches) {
        const checkedAt = await readSysConfigTimestamp(env, buildPredictiveCheckedKey(match.id));
        if (checkedAt > 0 && (now - checkedAt) < PREDICTIVE_CHECK_COOLDOWN_MS) {
            continue;
        }
        predictiveCandidates.push(match);
    }

    let startingMatch = upcomingMatches.find(m => now >= m.start_time) || null;
    if (startingMatch) {
        const checkedAt = await readSysConfigTimestamp(env, buildPredictiveCheckedKey(startingMatch.id));
        if (checkedAt > 0 && (now - checkedAt) < PREDICTIVE_CHECK_COOLDOWN_MS) {
            startingMatch = null;
        }
    }

    const shouldFetchLive = (predictiveCandidates.length > 0 || !!startingMatch) === true;

    if (shouldFetchLive !== true) {
        console.log('[CONTROL_UNLOCK_SKIP] Predictive window closed. 0 API calls.');
        return [];
    }

    // --- RULE D: 1 call only ? /matches/v1/live ---
    console.log('[CONTROL_UNLOCK_STARTED] Lock acquired. 1 API call allow: /live');
    const data = await fetchEndpoint('/matches/v1/live', key, host);
    if (data) {
        await persistLiveStateClasses(env, data);
        await restoreTerminalStatusesFromNonTerminalApi(env, data, now);

        const liveSnapshotHash = buildLiveSnapshotHash(data);
        const previousLiveHash = liveSnapshotState?.hash || '';
        const sameLiveSnapshot = !!liveSnapshotHash && previousLiveHash === liveSnapshotHash;
        await writeSysConfigValue(env, LIVE_SNAPSHOT_HASH_KEY, JSON.stringify({
            hash: liveSnapshotHash,
            stableUntil: sameLiveSnapshot ? (now + LIVE_SNAPSHOT_SKIP_WINDOW_MS) : 0
        }));
        if (sameLiveSnapshot) {
            return [];
        }

        parsed.push(...data);
        await updateDBTimestamp(env, 'last_fetch_live');

        const attempted = [...predictiveCandidates];
        if (startingMatch && !attempted.some(m => String(m.id) === String(startingMatch.id))) {
            attempted.push(startingMatch);
        }
        const liveApiById = new Map((data || []).map(m => [String(m?.id || ''), m]));
        for (const candidate of attempted) {
            const candidateId = String(candidate?.id || '').trim();
            if (!candidateId) continue;

            const apiMatch = liveApiById.get(candidateId);
            const unchanged = isPredictiveStateUnchanged(candidate, apiMatch);
            const keyName = buildPredictiveCheckedKey(candidateId);

            if (unchanged) {
                await writeSysConfigTimestamp(env, keyName, now);
            } else {
                await clearSysConfigTimestamp(env, keyName);
            }
        }

        try {
            await reconcileStaleLiveMatches(env, data, now);
        } catch (_) {
            // Intentionally silent to keep existing live fetch behavior unchanged.
        }
    }

    // /upcoming ? DISABLED for controlled unlock
    console.log('[CONTROL_UNLOCK_DISABLED] /upcoming endpoint disabled.');

    // /recent ? DISABLED for controlled unlock
    console.log('[CONTROL_UNLOCK_DISABLED] /recent endpoint disabled.');

    if (parsed.length === 0) return [];

    // Deduplicate by ID
    const unique = new Map();
    parsed.forEach(m => { if (m.id) unique.set(m.id, m); });

    return Array.from(unique.values());
}


function parseCricbuzzMatches(data) {
    let matches = [];
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
    const state = String(info.state || '').trim();
    const stateUpper = state.toUpperCase();
    const rawStatusText = String(info.status || '').trim();
    const startTimeMs = parseInt(info.startDate) || Date.now();
    const nowMs = Date.now();
    const stateClass = classifyMatchStateClass(state, rawStatusText);

    if (stateClass === 'TERMINAL_COMPLETED') status = 'Completed';
    else if (stateClass === 'TERMINAL_ABANDONED') status = 'Abandoned';
    else if (stateClass === 'NON_TERMINAL') status = deriveNonTerminalStatus(startTimeMs, nowMs);
    else if (stateUpper === 'IN PROGRESS' || stateUpper === 'LIVE' || stateUpper === 'TOSS' || stateUpper === 'STUMPS' || stateUpper === 'INNINGS BREAK') status = deriveNonTerminalStatus(startTimeMs, nowMs);
    else if (stateUpper === 'PREVIEW' || stateUpper === 'UPCOMING') status = 'Upcoming';

    const t1 = info.team1 || {};
    const t2 = info.team2 || {};
    const score = rawStatusText;

    return {
        id: info.matchId.toString(),
        seriesId: (info.seriesId || '0').toString(),
        seriesName: info.seriesName || 'Unknown Series',
        title: `${t1.teamName || 'T1'} vs ${t2.teamName || 'T2'}`,
        shortTitle: `${t1.teamSName || 'T1'} vs ${t2.teamSName || 'T2'}`,
        status: status,
        stateClass: stateClass,
        matchFormat: info.matchFormat ? info.matchFormat.toUpperCase() : 'T20',

        // COMPATIBILITY FIELDS
        team1Name: t1.teamName || 'Team A',
        team2Name: t2.teamName || 'Team B',
        team1ShortName: t1.teamSName || 'T1',
        team2ShortName: t2.teamSName || 'T2',
        matchDesc: `${t1.teamName} vs ${t2.teamName}`,
        startDate: startTimeMs,
        endDate: parseInt(info.endDate) || (parseInt(info.startDate) + 14400000),
        venue: info.venueInfo ? info.venueInfo.ground : 'TBD',

        startTime: startTimeMs,

        teamA: t1.teamName || 'Team A',
        teamB: t2.teamName || 'Team B',
        teamAImg: t1.imageId ? `https://static.cricbuzz.com/a/img/v1/i1/c${t1.imageId}/i.jpg` : '',
        teamBImg: t2.imageId ? `https://static.cricbuzz.com/a/img/v1/i1/c${t2.imageId}/i.jpg` : '',

        team1Id: (t1.teamId || '0').toString(),
        team2Id: (t2.teamId || '0').toString(),

        lastUpdated: normalizeSnapshotInt(
            info.lastUpdated ||
            info.lastUpdatedTime ||
            info.lastUpdatedTs ||
            info.startDate
        ),

        lastScore: score,
        lastWickets: 0,
        lastOver: "0.0",
        lastInnings: 1
    };
}

// --- ZERO-COST CUSTOM SMART SCRAPER ---
async function fetchPublicLiveMatches(env) {
    const HEADERS = [
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/121.0'
    ];

    console.log("🚀 Custom Scraper Triggered");

    try {
        const response = await fetch('https://www.cricbuzz.com/cricket-match/live-scores', {
            headers: {
                'User-Agent': HEADERS[Math.floor(Math.random() * HEADERS.length)],
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
            }
        });

        if (!response.ok) {
            console.error(`Scraper HTTP Error: ${response.status}`);
            return [];
        }

        const data = await response.text();
        const matches = [];
        const unique = new Set();
        const now = Date.now();

        // Extract embedded JSON from React state
        const startStr = '\\"currentMatchesList\\":';
        const startIndex = data.indexOf(startStr);
        if (startIndex === -1) {
            console.error("Scraper Error: currentMatchesList not found in HTML");
            return [];
        }

        let searchStr = data.substring(startIndex + startStr.length);
        let openBraces = 0;
        let endIndex = -1;
        let inString = false;
        let escapeNext = false;

        for (let i = 0; i < searchStr.length; i++) {
            const char = searchStr[i];
            if (escapeNext) { escapeNext = false; continue; }
            if (char === '\\') { escapeNext = true; continue; }
            if (char === '"') { inString = !inString; continue; }
            if (!inString) {
                if (char === '{') openBraces++;
                if (char === '}') {
                    openBraces--;
                    if (openBraces === 0) { endIndex = i; break; }
                }
            }
        }

        if (endIndex === -1) {
            console.error("Scraper Error: Could not find end of JSON object");
            return [];
        }

        let rawJson = searchStr.substring(0, endIndex + 1);
        let unescaped = rawJson.replace(/\\\\"/g, '\\"').replace(/\\"/g, '"').replace(/\\\\\\\\/g, '\\\\');

        let parsedData;
        try {
            parsedData = JSON.parse(unescaped);
        } catch (e) {
            console.error("Scraper Parse Error:", e);
            return [];
        }

        if (!parsedData || !parsedData.typeMatches) return [];

        for (const typeMatch of parsedData.typeMatches) {
            if (!typeMatch.seriesMatches) continue;
            for (const seriesMatch of typeMatch.seriesMatches) {
                if (!seriesMatch.seriesAdWrapper || !seriesMatch.seriesAdWrapper.matches) continue;
                for (const matchObj of seriesMatch.seriesAdWrapper.matches) {
                    const info = matchObj.matchInfo;
                    if (!info || !info.team1 || !info.team2) continue;

                    const matchId = info.matchId ? info.matchId.toString() : "";
                    if (!matchId || unique.has(matchId)) continue;

                    const titleStr = info.status || "";
                    const team1 = info.team1.teamSName || "T1";
                    const team2 = info.team2.teamSName || "T2";
                    const stateTitle = info.stateTitle || "";

                    // Determine status more accurately
                    let status = "Upcoming";
                    const stateLower = (info.state || "").toLowerCase();
                    if (stateLower === 'complete' || stateLower === 'abandon' || titleStr.toLowerCase().includes('won')) {
                        status = "Completed";
                    } else if (stateLower === 'inprogress' || stateLower === 'stumps' || titleStr.toLowerCase().includes('live') || stateTitle.toLowerCase() === 'live') {
                        status = "Live";
                    } else if (stateLower === 'upcoming') {
                        status = "Upcoming";
                    } else if (info.status && info.status.toLowerCase().includes('stumps')) {
                        status = "Live";
                    }

                    // Score extraction
                    let lastScore = status === 'Live' ? 'In Progress' : status;
                    let lastWickets = 0;
                    let lastOver = "0.0";
                    let lastInnings = 1;

                    if (matchObj.matchScore) {
                        const ms = matchObj.matchScore;
                        let r1 = 0, w1 = 0, o1 = "0.0";
                        let r2 = 0, w2 = 0, o2 = "0.0";

                        if (ms.team1Score && ms.team1Score.inngs1) {
                            r1 = ms.team1Score.inngs1.runs || 0;
                            w1 = ms.team1Score.inngs1.wickets || 0;
                            o1 = ms.team1Score.inngs1.overs || "0.0";
                            lastScore = `${team1} ${r1}/${w1} (${o1})`;
                            lastInnings = 1;
                            lastWickets = w1;
                            lastOver = o1.toString();
                        }
                        if (ms.team1Score && ms.team1Score.inngs2) {
                            // Second innings for team1
                            const r = ms.team1Score.inngs2.runs || 0;
                            const w = ms.team1Score.inngs2.wickets || 0;
                            const o = ms.team1Score.inngs2.overs || "0.0";
                            lastScore += ` & ${r}/${w}`;
                        }
                        if (ms.team2Score && ms.team2Score.inngs1) {
                            r2 = ms.team2Score.inngs1.runs || 0;
                            w2 = ms.team2Score.inngs1.wickets || 0;
                            o2 = ms.team2Score.inngs1.overs || "0.0";
                            lastScore += `, ${team2} ${r2}/${w2} (${o2})`;
                            lastInnings = 2;
                            lastWickets = w2;
                            lastOver = o2.toString();
                        }
                        if (ms.team2Score && ms.team2Score.inngs2) {
                            // Second innings for team2
                            const r = ms.team2Score.inngs2.runs || 0;
                            const w = ms.team2Score.inngs2.wickets || 0;
                            const o = ms.team2Score.inngs2.overs || "0.0";
                            lastScore += ` & ${r}/${w}`;
                        }

                        if (titleStr) {
                            lastScore += ` - ${titleStr}`;
                        }
                    } else {
                        // Fallback to title string if available
                        if (titleStr) lastScore = titleStr;
                    }

                    // Premium Filter
                    const fullText = `${team1} ${team2} ${info.seriesName || ""} ${titleStr}`.toUpperCase();

                    const isPremium = [
                        'IPL', 'INDIAN PREMIER LEAGUE',
                        'BBL', 'BIG BASH',
                        'PSL', 'PAKISTAN SUPER LEAGUE',
                        'BPL', 'BANGLADESH PREMIER LEAGUE',
                        'SA20', 'CPL', 'HUNDRED', 'WPL',
                        'WORLD CUP', 'ICC', 'ASIA CUP', 'CHAMPIONS TROPHY',
                        'T20I', 'ODI', 'TEST', "WOMEN'S T20", "WOMEN'S ODI"
                    ].some(kw => fullText.includes(kw));

                    const isExcluded = [
                        'DOMESTIC', 'SHIELD', 'PLUNKET', 'RANJI', 'BLAST', 'CHALLENGER',
                        'TROPHY', 'CUP', 'LEAGUE'
                    ].some(kw => {
                        if (kw === 'TROPHY' && fullText.includes('CHAMPIONS TROPHY')) return false;
                        if (kw === 'CUP' && (fullText.includes('WORLD CUP') || fullText.includes('ASIA CUP'))) return false;
                        if (kw === 'LEAGUE' && (fullText.includes('PREMIER LEAGUE') || fullText.includes('SUPER LEAGUE') || fullText.includes('BIG BASH LEAGUE'))) return false;
                        return fullText.includes(kw);
                    });

                    if (!isPremium || isExcluded) {
                        continue;
                    }

                    unique.add(matchId);

                    matches.push({
                        id: matchId,
                        seriesId: info.seriesId ? info.seriesId.toString() : '0',
                        seriesName: info.seriesName || 'Public Scrape',
                        title: `${team1} vs ${team2}`,
                        shortTitle: `${team1} vs ${team2}`,
                        status: status,
                        teamA: team1,
                        teamB: team2,
                        team1Id: info.team1.teamId ? info.team1.teamId.toString() : '0',
                        team2Id: info.team2.teamId ? info.team2.teamId.toString() : '0',
                        startTime: info.startDate ? parseInt(info.startDate, 10) : now,
                        lastUpdated: now,
                        lastScore: lastScore,
                        lastWickets: lastWickets,
                        lastOver: lastOver.toString(),
                        lastInnings: lastInnings,
                        teamAImg: '',
                        teamBImg: ''
                    });
                }
            }
        }

        return matches;
    } catch (e) {
        console.error("Scraper Error:", e.message);
        return [];
    }
}
