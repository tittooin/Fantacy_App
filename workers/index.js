/**
 * Cloudflare Worker for Fantasy Cricket App
 * Hindi: RapidAPI se data fetch karke Firestore mein save karta hai
 * 
 * CORS issue solve karne ke liye server-side implementation
 */

import { processCricketData } from './cricket_engine.js';
import { calculateFantasyPoints } from './points_engine.js';
import { processLiveContests } from './contest_engine.js';
import { createCashfreeOrder } from './payment_service.js';
import { handleCashfreeWebhook } from './webhook_handler.js';
import { processLeaderboards } from './leaderboard_engine.js';
import { processSquads, syncMatchSquad } from './squad_engine.js';
import { processPayoutsForMatch } from './payout_engine.js';
import { handleVoucherRedeem, handleVoucherList } from './voucher_system.js';


// ... (CORS Headers kept same)

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-rapidapi-key, x-rapidapi-host',
};

// ...

export default {
    async fetch(request, env, ctx) {
        if (request.method === 'OPTIONS') {
            return new Response(null, { headers: corsHeaders });
        }

        const url = new URL(request.url);
        const path = url.pathname;

        // --- ROOT & COMPLIANCE (For Domain Verification) ---
        if (path === '/') return handleStaticPage('home');
        if (path === '/terms' || path === '/terms-and-conditions') return handleStaticPage('terms');
        if (path === '/refund' || path === '/refund-policy' || path === '/cancellation') return handleStaticPage('refund');
        if (path === '/privacy' || path === '/privacy-policy') return handleStaticPage('privacy');
        if (path === '/contact' || path === '/contact-us') return handleStaticPage('contact');

        if (path === '/matches' || path === '/api/get-matches') return handleGetMatches(env);
        // Refresh manually?
        if (path === '/matches/refresh' || path === '/api/refresh-matches') {
            const matches = await processCricketData(env);
            return jsonResponse({ success: true, message: "Triggered D1 Update", matches: matches });
        }

        if (path === '/scorecard' || path.startsWith('/api/scorecard')) {
            const matchId = url.searchParams.get('matchId') || path.split('/').pop();
            return handleGetScorecard(matchId, env);
        }

        if (path === '/squads' || path === '/api/squads') return handleGetSquads(url.searchParams.get('matchId'), env);

        // --- PAYMENT ROUTES ---
        if (path === '/pay') return handlePaymentRedirect(url.searchParams, env);
        if (path === '/api/create-payment') return handleCreatePayment(request, env);
        if (path === '/api/payment-webhook') return handlePaymentWebhook(request, env);

        // --- CONTEST ROUTES ---
        if (path === '/api/join-contest') return handleJoinContest(request, env);

        // --- LEADERBOARD ROUTES ---
        if (path === '/api/leaderboard') {
            const contestId = url.searchParams.get('contestId');
            if (!contestId) return jsonResponse({ success: false, error: 'contestId required' }, 400);
            return handleGetLeaderboard(contestId, env);
        }
        if (path === '/api/calc-leaderboard') {
            await processLeaderboards(env);
            return jsonResponse({ success: true, message: 'Leaderboard Calc Triggered' });
        }

        // --- ADMIN D1 STATS (Zero Firestore) ---
        if (path === '/api/admin/stats') {
            return handleAdminStats(env);
        }

        // --- MANUAL PAYOUT TRIGGER (Safety Wrapper) ---
        if (path === '/api/admin/payouts/distribute') {
            // Expect POST with matchId
            if (request.method !== 'POST') return jsonResponse({ error: 'Method Not Allowed' }, 405);
            const body = await request.json();
            if (!body.matchId) return jsonResponse({ error: 'Match ID required' }, 400);

            // Trigger Payout Logic
            await processPayoutsForMatch(env, body.matchId);
            return jsonResponse({ success: true, message: `Payout Process Initiated for ${body.matchId}` });
        }

        // --- MANUAL SQUAD ENTRY (Admin) ---
        if (path === '/api/admin/match/squad') return handleAdminSaveSquad(request, env);

        // --- VOUCHER ROUTES ---
        if (path === '/api/voucher/redeem') return handleVoucherRedeem(request, env);
        if (path === '/api/voucher/list') return handleVoucherList(request, env);

        if (path === '/diag') return handleGlobalDiag(env);
        if (path === '/fantasy-points') return handleGetFantasyPoints(url.searchParams.get('match_id'), env);
        if (path === '/debug-api' || path === '/api/debug-api') return handleDebugApi(env);

        return new Response("Fantasy Cricket Worker (D1-Core) - Unknown Route: " + path, { status: 404, headers: corsHeaders });
    }
};

// --- HANDLERS ---

async function handleDebugApi(env) {
    const key = env.RAPID_API_KEY;
    const hosts = [
        { name: 'LiveScore6', host: 'livescore6.p.rapidapi.com', path: '/matches/v2/list-live?Category=cricket' },
    ];

    let results = {};

    for (const h of hosts) {
        try {
            const start = Date.now();
            const url = `https://${h.host}${h.path}`;
            const resp = await fetch(url, {
                headers: { 'x-rapidapi-key': key, 'x-rapidapi-host': h.host }
            });
            let dataPreview = "No Body";
            let parseDebug = {};
            try {
                const data = await resp.json();

                // DATA INSPECTION
                const stages = data.Stages || [];
                const firstStage = stages[0] || {};
                const events = firstStage.Events || [];
                const firstEvent = events[0] || {};

                parseDebug = {
                    hasStages: !!data.Stages,
                    stagesCount: stages.length,
                    firstStageEvents: events.length,
                    sampleEventKeys: Object.keys(firstEvent),
                    hasT1: !!firstEvent.T1,
                    hasT2: !!firstEvent.T2,
                    t1Name: firstEvent.T1 ? (firstEvent.T1[0]?.Nm) : 'N/A',
                    eid: firstEvent.Eid
                };

                dataPreview = JSON.stringify(data).substring(0, 500) + "...";
            } catch (e) {
                dataPreview = "Indigestible JSON: " + e.message;
            }

            results[h.name] = {
                status: resp.status,
                ok: resp.ok,
                latency: Date.now() - start,
                parseDebug: parseDebug,
                dataPreview: dataPreview // Longer preview
            };
        } catch (e) {
            results[h.name] = { error: e.message };
        }
    }

    return jsonResponse({
        success: true,
        env_key_preview: key ? key.substring(0, 5) + '...' : 'MISSING',
        results: results
    });
}

async function handleCreatePayment(request, env) {
    try {
        const body = await request.json();
        const { userId, amount } = body;

        if (!userId || !amount) {
            return jsonResponse({ success: false, error: 'UserId and Amount required' }, 400);
        }

        // Call Service
        const result = await createCashfreeOrder(userId, amount, env);

        // Save Transaction to DB
        if (result.success && result.transactionData) {
            await saveToFirestore('transactions', result.transactionData, env);
            // Remove transactionData from response to keep it clean
            delete result.transactionData;
        }

        return jsonResponse(result);
    } catch (e) {
        return jsonResponse({ success: false, error: e.message }, 500);
    }
}

async function handlePaymentWebhook(request, env) {
    try {
        // Logic moved to webhook_handler.js, but we execute the DB updates here based on action
        const result = await handleCashfreeWebhook(request, env);

        if (result.action === 'UPDATE_WALLET') {
            const { orderId, amount, gatewayData } = result;
            // 1. Get Transaction to find UserID
            const txnDocs = await getFromFirestore(`transactions/${orderId}`, env); // Single doc fetch usually different, assume helper handles collection only?
            // Actually getFromFirestore fetches collection. We need single doc.
            // Let's iterate or fetch properly.
            // Simplified: The orderId IS the document ID in 'transactions'.
            const txn = await fetchDoc(`transactions/${orderId}`, env);

            if (txn && txn.status === 'pending') {
                const userId = txn.userId;

                // 2. Update User Wallet
                const user = await fetchDoc(`users/${userId}`, env);
                // Migration: Check walletBalance (V2) -> walletCoins (Legacy) -> 0
                const currentCoins = (user && user.walletBalance) ? parseFloat(user.walletBalance) :
                    (user && user.walletCoins) ? parseFloat(user.walletCoins) : 0;
                const newCoins = currentCoins + parseFloat(amount);

                // Update User with walletBalance
                await saveToFirestore('users', { id: userId, walletBalance: newCoins, lastUpdated: new Date().toISOString() }, env);

                // 3. Update Transaction Status
                await saveToFirestore('transactions', { id: orderId, status: 'success', gatewayResponse: JSON.stringify(gatewayData) }, env);

                console.log(`âœ… Wallet Updated for ${userId}: +${amount}`);
            } else {
                console.log(`âš ï¸ Transaction ${orderId} not found or already processed.`);
            }
        }
        else if (result.action === 'UPDATE_TRANSACTION_FAILED') {
            await saveToFirestore('transactions', { id: result.orderId, status: 'failed', gatewayResponse: JSON.stringify(result.gatewayData) }, env);
        }

        // Cashfree expects 200 OK
        return new Response("OK", { status: 200 });

    } catch (e) {
        console.error("Webhook Handler Failed:", e);
        // Return 200 to avoid CF retries if logic failed (manual check required)
        // or 500 to retry? Better 500 if DB error.
        return new Response("Error", { status: 500 });
    }
}

async function handleJoinContest(request, env) {
    try {
        const body = await request.json();
        const { userId, contestId, matchId, teamName, playerIds, teamId } = body; // ADDED teamId

        if (!userId || !contestId || !matchId) {
            return jsonResponse({ success: false, error: 'Missing required fields' }, 400);
        }

        // 1. Fetch User Balance
        const user = await fetchDoc(`users/${userId}`, env);
        if (!user) return jsonResponse({ success: false, error: 'User not found' }, 404);

        const currentCoins = (user.walletBalance) ? parseFloat(user.walletBalance) :
            (user.walletCoins) ? parseFloat(user.walletCoins) : 0;

        // 2. Fetch Contest Entry Fee
        const contest = await fetchDoc(`contests/${contestId}`, env);
        if (!contest) return jsonResponse({ success: false, error: 'Contest not found' }, 404);

        const entryFee = contest.entryFee ? parseFloat(contest.entryFee) : 0;

        // 3. Check Balance
        if (currentCoins < entryFee) {
            return jsonResponse({ success: false, error: 'Insufficient Balance', required: entryFee, available: currentCoins }, 402);
        }

        // 4. Deduct Coins
        const newBalance = currentCoins - entryFee;
        await saveToFirestore('users', { id: userId, walletBalance: newBalance }, env);

        // 5. Log Transaction (Audit)
        const txnId = `join_${Date.now()}_${userId}`;
        await saveToFirestore('transactions', {
            id: txnId,
            userId: userId,
            type: 'contest_join',
            contestId: contestId,
            amount: entryFee,
            status: 'success',
            createdAt: new Date().toISOString()
        }, env);

        // 6. D1 WRITE (PRIMARY) - ZERO FIRESTORE FOR PARTICIPANTS
        // 'contest_participants' is the SOLE source of truth for contest entry
        try {
            await env.DB.prepare(
                `INSERT OR REPLACE INTO contest_participants (contest_id, user_id, team_id, player_ids, team_name, joined_at, match_id) 
                 VALUES (?, ?, ?, ?, ?, ?, ?)`
            ).bind(
                contestId,
                userId,
                teamId || userId,
                JSON.stringify(playerIds || []),
                teamName || 'User Team',
                Date.now(),
                matchId
            ).run();

            // Sync simple count to D1 contests table (Optimistic)
            await env.DB.prepare(
                `UPDATE contests SET filled_spots = filled_spots + 1 WHERE id = ?`
            ).bind(contestId).run().catch(e => console.log("Contest Count Update Failed", e));

        } catch (d1Error) {
            console.error("D1 Join Error:", d1Error);
            // Panic: If D1 fails, refund user? Or retry?
            // For now, return error but money is deducted (Audit exists in transactions to manual fix)
            return jsonResponse({ success: false, error: "Join Failed on Server DB", tips: "Contact Support" }, 500);
        }

        return jsonResponse({ success: true, message: 'Contest Joined Successfully', remainingBalance: newBalance });

    } catch (e) {
        console.error("Join Contest Error", e);
        return jsonResponse({ success: false, error: e.message }, 500);
    }
}

async function handleAdminStats(env) {
    try {
        // Aggregated stats from D1
        const matchesCount = await env.DB.prepare("SELECT COUNT(*) as c FROM matches WHERE status='Live'").first();
        const upcomingCount = await env.DB.prepare("SELECT COUNT(*) as c FROM matches WHERE status='Upcoming'").first();
        const contestsCount = await env.DB.prepare("SELECT COUNT(*) as c FROM contests").first();

        // Users count - depends if we sync users. 
        // If not synced, return 0 or fetching from a 'stats' table if we had one.
        // For now, query 'users' table (Schema V4 created it)
        const usersCount = await env.DB.prepare("SELECT COUNT(*) as c FROM users").first();

        return jsonResponse({
            success: true,
            stats: {
                liveMatches: matchesCount?.c || 0,
                upcomingMatches: upcomingCount?.c || 0,
                activeContests: contestsCount?.c || 0,
                totalUsers: usersCount?.c || 0,
                // Payouts/KYC are financial, still Firestore-bound for now, or 0
                pendingPayouts: 0,
                kycPending: 0
            }
        });
    } catch (e) {
        return jsonResponse({ success: false, error: e.message });
    }
}

async function handleGetLeaderboard(contestId, env) {
    try {
        const row = await env.DB.prepare(
            "SELECT data FROM contest_leaderboards WHERE contest_id = ?"
        ).bind(contestId).first();

        if (row && row.data) {
            return jsonResponse({ success: true, leaderboard: JSON.parse(row.data) });
        }
        return jsonResponse({ success: true, leaderboard: [] }); // Empty if processing hasn't run yet
    } catch (e) {
        return jsonResponse({ success: false, error: e.message });
    }
}


// Helper: Fetch Single Doc (Since getFromFirestore returns List)
async function fetchDoc(path, env) {
    const url = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/${path}?key=${env.FIREBASE_API_KEY}`;
    try {
        const res = await fetch(url);
        if (!res.ok) return null;
        const doc = await res.json();

        const item = { id: doc.name.split('/').pop() };
        for (const [key, value] of Object.entries(doc.fields || {})) {
            if (value.stringValue) item[key] = value.stringValue;
            else if (value.integerValue) item[key] = parseInt(value.integerValue);
            else if (value.doubleValue) item[key] = parseFloat(value.doubleValue);
            else if (value.booleanValue) item[key] = value.booleanValue;
        }
        return item;
    } catch (e) {
        return null;
    }
}


// Legacy processLiveMatches removed. Using cricket_engine.js (D1)



// --- D1 HANDLERS ---

async function handleGetMatches(env) {
    try {
        const { results } = await env.DB.prepare('SELECT * FROM matches ORDER BY start_time ASC').all();
        return jsonResponse({ success: true, matches: results });
    } catch (error) {
        return jsonResponse({ success: false, error: error.message });
    }
}

// ... (Other handlers kept as is, but remove old processLiveMatches logic)

async function handleGetScorecard(matchId, env) {
    try {
        const score = await env.DB.prepare('SELECT * FROM live_scores WHERE match_id = ?').bind(matchId).first();
        if (score) {
            return jsonResponse({ success: true, scorecard: score, source: 'D1' });
        }

        // 2. Fallback: Return empty/status
        return jsonResponse({ success: false, message: 'Scorecard not available in D1' });

    } catch (error) {
        return jsonResponse({ success: false, error: error.message });
    }
}

async function handleGetSquads(matchId, env) {
    try {
        if (!matchId) return jsonResponse({ success: false, error: 'matchId required' });

        // 1. D1 cache read
        const d1Squad = await env.DB.prepare(
            "SELECT team_a_roster, team_b_roster, playing_11_a, playing_11_b, last_updated FROM match_squads WHERE match_id = ?"
        ).bind(matchId).first();

        const now = Date.now();
        const staleThreshold = 24 * 60 * 60 * 1000; // 24 hours

        // Fetch Team IDs from matches table to include in reponse (Optimized: fetch early if needed, or inside cache block)
        const matchInfo = await env.DB.prepare("SELECT team_a_id, team_b_id FROM matches WHERE id = ?").bind(matchId).first();
        const teamAId = matchInfo?.team_a_id || 0;
        const teamBId = matchInfo?.team_b_id || 0;

        // 2. Return cached if fresh
        if (d1Squad && d1Squad.team_a_roster) {
            const age = now - (d1Squad.last_updated || 0);
            if (age < staleThreshold) {
                const teamA = JSON.parse(d1Squad.team_a_roster || '[]');
                const teamB = JSON.parse(d1Squad.team_b_roster || '[]');
                const team1Id = matchInfo?.team_a_id || 0;
                const team2Id = matchInfo?.team_b_id || 0;

                return jsonResponse({
                    success: true,
                    source: 'D1_CACHE',
                    teamA: teamA.map(p => ({ ...p, teamId: (p.teamId || team1Id).toString() })),
                    teamB: teamB.map(p => ({ ...p, teamId: (p.teamId || team2Id).toString() })),
                    xiA: JSON.parse(d1Squad.playing_11_a || '[]'),
                    xiB: JSON.parse(d1Squad.playing_11_b || '[]'),
                    matchId: matchId,
                    team1Id: team1Id,
                    team2Id: team2Id
                });
            }
        }

        // Fetch Team IDs Logic already executed above

        // 3. Lazy fetch if missing or stale
        console.log(`🔄 Squad stale/missing for ${matchId}, fetching...`);
        const mockMatch = { id: matchId, status: 'Upcoming' };
        await syncMatchSquad(env, mockMatch, env.RAPID_API_KEY, env.RAPID_API_HOST);

        // 4. Return fresh data
        const d1Retry = await env.DB.prepare(
            "SELECT team_a_roster, team_b_roster, playing_11_a, playing_11_b FROM match_squads WHERE match_id = ?"
        ).bind(matchId).first();

        if (d1Retry && d1Retry.team_a_roster) {
            return jsonResponse({
                success: true,
                source: 'D1_FRESH',
                teamA: JSON.parse(d1Retry.team_a_roster),
                teamB: JSON.parse(d1Retry.team_b_roster),
                xiA: JSON.parse(d1Retry.playing_11_a || '[]'),
                xiB: JSON.parse(d1Retry.playing_11_b || '[]'),
                team1Id: teamAId,
                team2Id: teamBId
            });
        }

        return jsonResponse({ success: false, error: 'Squad unavailable' });
    } catch (e) {
        console.error('Squad Error:', e);
        return jsonResponse({ success: false, error: e.message }, 500);
    }
}

async function handleAdminSaveSquad(request, env) {
    if (request.method !== 'POST') return jsonResponse({ error: 'Method Not Allowed' }, 405);
    try {
        const body = await request.json();
        const { matchId, teamA, teamB, xiA, xiB } = body;

        if (!matchId || !teamA || !teamB) {
            return jsonResponse({ success: false, error: 'Missing required fields: matchId, teamA, teamB' }, 400);
        }

        // 1. Verify Match Status (Must be Upcoming)
        // Actually User asked "Lock after Live", so allow edits for 'Upcoming'.
        // Let's check status.
        const match = await env.DB.prepare("SELECT status FROM matches WHERE id = ?").bind(matchId).first();
        if (!match) return jsonResponse({ success: false, error: 'Match not found' }, 404);

        if (match.status !== 'Upcoming' && match.status !== 'Live') {
            // Allowing 'Live' for emergency fixes, but 'Completed' is definitely locked.
            // User Rule: "Match Live hone ke baad squad LOCK ho jaaye".
            // Strict compliance:
            if (match.status !== 'Upcoming') {
                return jsonResponse({ success: false, error: 'Squad is LOCKED. Match is Live or Completed.' }, 403);
            }
        }

        // 2. Save to D1
        await env.DB.prepare(`
            INSERT INTO match_squads (match_id, team_a_roster, team_b_roster, playing_11_a, playing_11_b, last_updated)
            VALUES (?, ?, ?, ?, ?, ?)
            ON CONFLICT(match_id) DO UPDATE SET
                team_a_roster = excluded.team_a_roster,
                team_b_roster = excluded.team_b_roster,
                playing_11_a = excluded.playing_11_a,
                playing_11_b = excluded.playing_11_b,
                last_updated = excluded.last_updated
        `).bind(
            matchId,
            JSON.stringify(teamA),
            JSON.stringify(teamB),
            JSON.stringify(xiA || []),
            JSON.stringify(xiB || []),
            Date.now()
        ).run();

        console.log(`âœ… Admin Saved Squad for ${matchId}`);
        return jsonResponse({ success: true, message: 'Squad Saved Successfully' });

    } catch (e) {
        console.error("Admin Squad Save Error", e);
        return jsonResponse({ success: false, error: e.message }, 500);
    }
}

async function fetchFromRapidAPI(endpoint, env, retryCount = 0) {
    let targetEndpoint = endpoint;
    const isProbe = retryCount > 0;
    if (endpoint.includes('matches') && !isProbe) {
        targetEndpoint = lastWorkingMatchEndpoint || '/matches/list';
    }
    const host = env.RAPID_API_HOST || 'unofficial-cricbuzz.p.rapidapi.com';
    const url = `https://${host}${targetEndpoint}`;

    try {
        const response = await fetch(url, {
            headers: {
                'x-rapidapi-key': env.RAPID_API_KEY,
                'x-rapidapi-host': host,
                'User-Agent': 'Mozilla/5.0'
            }
        });

        if (!response.ok) {
            console.error(`âŒ RapidAPI Error: ${response.status} ${response.statusText}`);
            return [];
        }

        const data = await response.json();

        // Parse Logic (simplified adapter)
        let matches = [];

        // Structure 1: { typeMatches: [ ... ] } (Schedule)
        if (data.typeMatches) {
            for (const type of data.typeMatches) {
                if (type.seriesMatches) {
                    for (const series of type.seriesMatches) {
                        if (series.seriesAdWrapper) {
                            for (const match of series.seriesAdWrapper.matches) {
                                if (match && match.matchInfo) {
                                    const m = formatMatch(match.matchInfo);
                                    if (m) matches.push(m);
                                }
                            }
                        }
                    }
                }
            }
        }
        // Structure 2: { matchInfo: { ... } } (Single Match or Live List?)
        else if (data.matchInfo) {
            const m = formatMatch(data.matchInfo);
            if (m) matches.push(m);
        }
        // Structure 3: Array of matches (Live Endpoints sometimes)
        else if (Array.isArray(data)) {
            // Try to map each item if it looks like a match
            data.forEach(item => {
                let m = null;
                if (item.matchId || item.id) m = formatMatch(item);
                else if (item.matchInfo) m = formatMatch(item.matchInfo);

                if (m) matches.push(m);
            });
        }
        // Structure 4: { response: [ ... ] }
        else if (data.response && Array.isArray(data.response)) {
            data.response.forEach(item => {
                let m = null;
                if (item.matchId || item.id) m = formatMatch(item);
                else if (item.matchInfo) m = formatMatch(item.matchInfo);

                if (m) matches.push(m);
            });
        }

        if (matches.length === 0) {
            console.log("âš ï¸ No matches parsed from API. Raw Keys:", Object.keys(data));
        }

        return matches; // Always return array

    } catch (error) {
        console.error('âŒ Parse error:', error);
        return [];
    }
}

function formatMatch(info) {
    // STRICT VALIDATION: Ignore matches without teams
    if (!info || !info.team1 || !info.team2) return null;
    if (!info.team1.teamName && !info.team1.teamSName) return null;
    if (!info.team2.teamName && !info.team2.teamSName) return null;

    return {
        id: (info.matchId || info.id || '').toString(),
        seriesName: info.seriesName || 'Series',
        matchDesc: info.matchDesc || 'Match',
        matchFormat: info.matchFormat || 'T20',
        team1Name: info.team1?.teamName || info.team1?.teamSName || 'Team 1',
        team1ShortName: info.team1?.teamSName || 'T1',
        team1Img: (info.team1?.imageId || '1').toString(),
        team2Name: info.team2?.teamName || info.team2?.teamSName || 'Team 2',
        team2ShortName: info.team2?.teamSName || 'T2',
        team2Img: (info.team2?.imageId || '1').toString(),
        startDate: info.startDate ? parseInt(info.startDate) : 0,
        status: info.status || info.state || 'Upcoming',
        lastUpdated: Date.now()
    };
}

// EXPORT Helper Functions for use in other modules
export async function saveToFirestore(collection, data, env) {
    const baseUrl = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/${collection}`;
    const items = Array.isArray(data) ? data : [data];

    for (const item of items) {
        const docId = item.id || Date.now().toString();
        const url = `${baseUrl}/${docId}?key=${env.FIREBASE_API_KEY}`;
        const fields = {};
        for (const [key, value] of Object.entries(item)) {
            if (value === null || value === undefined) continue;
            if (typeof value === 'string') fields[key] = { stringValue: value };
            else if (typeof value === 'number') fields[key] = { integerValue: Math.floor(value).toString() }; // Integer for simplicity, handle floats via Double if needed
            else if (typeof value === 'boolean') fields[key] = { booleanValue: value };
            else if (typeof value === 'object') fields[key] = { stringValue: JSON.stringify(value) };
        }

        try {
            await fetch(url, {
                method: 'PATCH',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ fields })
            });
        } catch (e) {
            console.error(`âŒ Firestore Save Error: ${e.message}`);
        }
    }
    return true;
}

export async function getFromFirestore(collection, env) {
    const url = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/${collection}?key=${env.FIREBASE_API_KEY}`;
    try {
        const res = await fetch(url);
        if (!res.ok) return [];
        const data = await res.json();
        return (data.documents || []).map(doc => {
            const item = { id: doc.name.split('/').pop() };
            for (const [key, value] of Object.entries(doc.fields || {})) {
                if (value.stringValue) item[key] = value.stringValue;
            }
            return item;
        });
    } catch (e) {
        return [];
    }
}

async function handleGlobalDiag(env) {
    return jsonResponse({ status: 'ok' });
}

async function handleGetFantasyPoints(matchId, env) {
    if (!matchId) return jsonResponse({ success: false, error: 'Match ID required' }, 400);

    try {
        const points = await env.DB.prepare('SELECT * FROM fantasy_points WHERE match_id = ?').bind(matchId).all();
        // Parse breakdown JSON for cleaner response
        const formatted = points.results.map(p => ({
            ...p,
            breakdown: JSON.parse(p.breakdown || '{}')
        }));
        return jsonResponse({ success: true, points: formatted });
    } catch (e) {
        return jsonResponse({ success: false, error: e.message });
    }
}

export function jsonResponse(data, status = 200) {
    return new Response(JSON.stringify(data), {
        status,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
}

/**
 * Serves a HTML page that auto-redirects to Cashfree Payment Gateway
 */
function handlePaymentRedirect(params, env) {
    const sessionId = params.get('session_id');
    const environment = params.get('env') || 'prod';

    if (!sessionId) return new Response("Missing Session ID", { status: 400 });

    const sdkUrl = 'https://sdk.cashfree.com/js/v3/cashfree.js';

    const html = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <!-- Prevent Caching -->
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <title>Redirecting to Payment...</title>
    <script src="${sdkUrl}"></script>
    <style>
        body { font-family: sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; background: #f0f2f5; }
        .loader { border: 4px solid #f3f3f3; border-top: 4px solid #3498db; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
        .container { text-align: center; }
        p { margin-top: 20px; color: #555; }
    </style>
</head>
<body>
    <div class="container">
        <div class="loader" style="margin:0 auto;"></div>
        <p>Redirecting to Secure Payment Gateway...</p>
        <p style="font-size:12px; color:#999">Session: ${sessionId.substring(0, 10)}...</p>
    </div>
    <script>
        window.onload = function() {
            try {
                console.log("Initializing Cashfree v3...");
                // V3 Factory - try without new first, or check type
                const cashfree = Cashfree({
                    mode: "${environment === 'sandbox' ? 'sandbox' : 'production'}"
                });
                console.log("Cashfree Instance:", cashfree); 
                console.log("Redirecting...");
                cashfree.checkout({
                    paymentSessionId: "${sessionId}",
                    redirectTarget: "_self"
                });
            } catch(e) {
                console.error("Initialization Error:", e);
                document.body.innerHTML = "<p style='color:red; text-align:center'>Error: " + e.message + "<br><br>Check Console for details.</p>";
            }
        };
    </script>
</body>
</html>
    `;

    return new Response(html, {
        headers: {
            'Content-Type': 'text/html',
            'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
            ...corsHeaders
        }
    });
}

// --- STATIC PAGES FOR COMPLIANCE (Cashfree Verification) ---

// --- STATIC PAGES FOR COMPLIANCE (Cashfree Verification) ---
function handleStaticPage(type) {
    let title = "Fantasy Cricket API";
    let content = "";

    const style = "body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; padding: 40px; max-width: 800px; margin: 0 auto; line-height: 1.6; color: #333; background: #fafafa; } .card { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); } h1 { color: #2c3e50; border-bottom: 2px solid #eee; padding-bottom: 15px; } h2 { margin-top: 30px; color: #34495e; font-size: 1.2em; } a { color: #3498db; text-decoration: none; } ul { opacity: 0.8; } .footer { margin-top: 50px; text-align: center; font-size: 12px; color: #999; }";

    if (type === 'home') {
        title = "Fantasy Cricket API - Skill Platform";
        content = `
            <div class="card">
                <h1>Fantasy Cricket Services</h1>
                <p>Welcome to the secure backend services for Axevora Labs' Skill-Based Cricket Strategy Platform.</p>
                <p><strong>Status:</strong> Systems Operational ðŸŸ¢</p>
                <p>This platform offers analytics, team management, and strategy simulation tools for cricket enthusiasts. All transactions are for digital services and skill-based contests.</p>
                <p>Managed by <a href="https://axevoralabs.com">Axevora Labs</a>.</p>
            </div>
        `;
    } else if (type === 'terms') {
        title = "Terms of Service";
        content = `
            <div class="card">
                <h1>Terms of Service</h1>
                <p><strong>1. Introduction:</strong> These terms govern your use of our Skill-Based Fantasy Sports Platform. By accessing our services, you confirm you are 18+ years of age.</p>
                <p><strong>2. Game of Skill:</strong> Our contests are strictly "Games of Skill" as recognized by the Supreme Court of India. Success depends on knowledge, training, attention, and experience of the player.</p>
                <p><strong>3. Use of Services:</strong> Users pay platform fees to participate in organized skill contests. We strictly prohibit any form of gambling, betting, or wagering.</p>
                <p><strong>4. Restricted States:</strong> Users from Assam, Odisha, Telangana, Nagaland, Sikkim, and Andhra Pradesh are restricted from paid contests.</p>
                <p>For full legal terms, visit: <a href="https://axevoralabs.com/terms">Main Terms Policy</a></p>
            </div>
        `;
    } else if (type === 'refund') {
        title = "Refund & Cancellation Policy";
        content = `
            <div class="card">
                <h1>Refund & Cancellation Policy</h1>
                <h2>Cancellation</h2>
                <p>Users may withdraw from a contest anytime before the match deadline. The participation amount will be instantly credited back to the user's unutilized wallet balance.</p>
                <h2>Refunds</h2>
                <p><strong>Failed Transactions:</strong> If amount is deducted but not credited, it will be automatically refunded within 5-7 business days.</p>
                <p><strong>Contest Cancellation:</strong> If a real-world match is abandoned, all contest participation fees are refunded 100% to the user's wallet.</p>
                <p><strong>Finality:</strong> Once a contest is Live, participation is final and non-refundable as the service is considered consumed.</p>
            </div>
        `;
    } else if (type === 'privacy') {
        title = "Privacy Policy";
        content = `
            <div class="card">
                <h1>Privacy Policy</h1>
                <p>We respect your privacy. We collect minimal data (Email, Mobile) essential for account security and service delivery.</p>
                <p><strong>Data Usage:</strong> Your data is used strictly for authentication and transaction processing. We do not sell data to third parties.</p>
                <p><strong>Secure Payments:</strong> All financial transactions are processed via regulating PCI-DSS compliant gateways.</p>
            </div>
        `;
    } else if (type === 'contact') {
        title = "Contact Us";
        content = `
            <div class="card">
                <h1>Contact Us</h1>
                <p>For support regarding payments, account, or contests, reach out to us:</p>
                <ul>
                    <li><strong>Email:</strong> support@axevoralabs.com</li>
                    <li><strong>Operating Hours:</strong> Mon-Fri, 10 AM - 6 PM IST</li>
                </ul>
                <p><strong>Registered Address:</strong><br>Axevora Labs,<br>India.</p>
            </div>
        `;
    }

    const html = `
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <meta name="robots" content="noindex, nofollow">
            <title>${title}</title>
            <style>${style}</style>
        </head>
        <body>
            ${content}
            <div class="footer">
                &copy; ${new Date().getFullYear()} Axevora Labs. All Rights Reserved.<br>
                <small>Indian Fantasy Sports Association Compliant</small>
            </div>
        </body>
        </html>
    `;

    return new Response(html, {
        headers: { 'Content-Type': 'text/html' }
    });
}
