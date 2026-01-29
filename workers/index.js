/**
 * Cloudflare Worker for Fantasy Cricket App
 * Hindi: RapidAPI se data fetch karke Firestore mein save karta hai
 * 
 * CORS issue solve karne ke liye server-side implementation
 */

import { calculateFantasyPoints } from './points_engine.js';
import { processLiveContests } from './contest_engine.js';
import { createCashfreeOrder } from './payment_service.js';
import { handleCashfreeWebhook } from './webhook_handler.js';

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, x-rapidapi-key, x-rapidapi-host',
};

// Global State (In-Memory Cache)
// Note: Workers reset frequently, so this is short-lived cache.
let lastWorkingMatchEndpoint = '/matches/list';

export default {
    async fetch(request, env, ctx) {
        if (request.method === 'OPTIONS') {
            return new Response(null, { headers: corsHeaders });
        }

        const url = new URL(request.url);
        const path = url.pathname;

        // Routing - Support both clean paths and Flutter App's /api/ convention
        if (path === '/matches' || path === '/api/get-matches') return handleGetMatches(env);
        if (path === '/matches/refresh' || path === '/api/refresh-matches') return handleRefreshMatches(env, request);

        // Scorecard: Support query param or path param
        if (path === '/scorecard') return handleGetScorecard(url.searchParams.get('matchId'), env);
        if (path.startsWith('/api/scorecard/')) {
            const matchId = path.split('/').pop(); // Extracts ID from /api/scorecard/12345
            return handleGetScorecard(matchId, env);
        }

        if (path === '/squads' || path === '/api/squads') return handleGetSquads(url.searchParams.get('matchId'), env);

        // --- PAYMENT ROUTES ---
        if (path === '/api/create-payment') return handleCreatePayment(request, env);
        if (path === '/api/payment-webhook') return handlePaymentWebhook(request, env);

        // --- CONTEST ROUTES ---
        // Secure server-side join to ensure wallet deduction
        if (path === '/api/join-contest') return handleJoinContest(request, env);

        if (path === '/diag') return handleGlobalDiag(env);

        return new Response("Fantasy Cricket Worker Live! (v2.1 - Opt) - Unknown Route: " + path, { status: 404, headers: corsHeaders });
    },

    // Scheduled Event (Cron Trigger)
    // Runs every 2 minutes (configured in wrangler.toml)
    async scheduled(event, env, ctx) {
        console.log("⏰ Cron Triggered: Checking Live Matches...");

        // 1. Refresh Live Matches & Scores
        await processLiveMatches(env); // In this file

        // 2. Run Contest Engine (Leaderboard Updates)
        await processLiveContests(env, null); // In contest_engine.js
    }
};

// --- HANDLERS ---

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
                const currentCoins = user && user.walletCoins ? parseFloat(user.walletCoins) : 0;
                const newCoins = currentCoins + parseFloat(amount);

                // Update User
                await saveToFirestore('users', { id: userId, walletCoins: newCoins, lastUpdated: new Date().toISOString() }, env);

                // 3. Update Transaction Status
                await saveToFirestore('transactions', { id: orderId, status: 'success', gatewayResponse: JSON.stringify(gatewayData) }, env);

                console.log(`✅ Wallet Updated for ${userId}: +${amount}`);
            } else {
                console.log(`⚠️ Transaction ${orderId} not found or already processed.`);
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
        const { userId, contestId, matchId, teamName, playerIds } = body; // playerIds if we select team here, or teamId if separate

        if (!userId || !contestId || !matchId) {
            return jsonResponse({ success: false, error: 'Missing required fields' }, 400);
        }

        // 1. Fetch User Balance
        const user = await fetchDoc(`users/${userId}`, env);
        if (!user) return jsonResponse({ success: false, error: 'User not found' }, 404);

        const currentCoins = user.walletCoins ? parseFloat(user.walletCoins) : 0;

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
        await saveToFirestore('users', { id: userId, walletCoins: newBalance }, env);

        // 5. Log Transaction
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

        // 6. Add Participant to Contest (Subcollection)
        // contests/{contestId}/participants/{userId}
        await saveToFirestore(`contests/${contestId}/participants`, {
            id: userId,
            name: user.name || 'Unknown', // Ideally fetch from user doc
            teamName: teamName || `Team ${userId.substring(0, 4)}`,
            playerIds: playerIds || [],
            totalPoints: 0,
            rank: 0,
            joinedAt: new Date().toISOString()
        }, env);

        return jsonResponse({ success: true, message: 'Contest Joined Successfully', remainingBalance: newBalance });

    } catch (e) {
        console.error("Join Contest Error", e);
        return jsonResponse({ success: false, error: e.message }, 500);
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

/**
 * Phase 3: Points Engine & Live Score Processing
 * OPTIMIZED: Only write updates if points changed (Delta Updates)
 */
async function processLiveMatches(env) {
    const apiKey = env.RAPID_API_KEY;
    const apiHost = env.RAPID_API_HOST || 'free-cricbuzz-cricket-api.p.rapidapi.com';

    try {
        // console.log(`📡 Fetching Live Scores...`);
        const response = await fetch(`https://${apiHost}/cricket-livescores`, {
            method: 'GET',
            headers: {
                'x-rapidapi-key': apiKey,
                'x-rapidapi-host': apiHost
            }
        });

        if (!response.ok) throw new Error(`API Error: ${response.status}`);
        const data = await response.json();

        // Handle API wrapper
        const liveMatches = data.response || (Array.isArray(data) ? data : []) || [];
        console.log(`Live Matches: ${liveMatches.length}`);

        for (const match of liveMatches) {
            const matchId = match.matchId || match.id || match.match_id;
            if (!matchId) continue;

            const playerStatsList = extractPlayerStats(match);

            // OPTIMIZATION: Read existing players first to avoid unnecessary writes
            const existingPlayersMap = await fetchCollectionMap(env, `matches/${matchId}/players`);

            let updates = [];

            for (const stats of playerStatsList) {
                const pid = stats.playerId.toString();
                const fantasy = calculateFantasyPoints(stats);

                const existing = existingPlayersMap[pid];

                // Check if points changed
                if (!existing || existing.fantasyPoints !== fantasy.points) {
                    updates.push({
                        id: pid,
                        ...stats,
                        fantasyPoints: fantasy.points,
                        fantasyBreakdown: fantasy.breakdown,
                        lastUpdated: new Date().toISOString()
                    });
                }
            }

            if (updates.length > 0) {
                console.log(`⚡ Match ${matchId}: Updating ${updates.length} players (Saved ${playerStatsList.length - updates.length} writes)`);

                const batchPromises = updates.map(p => saveToFirestore(`matches/${matchId}/players`, p, env));
                await Promise.all(batchPromises);

                await updateLeaderboard(matchId, env);
            } else {
                console.log(`💤 Match ${matchId}: No point changes. Skipping write.`);
            }
        }

    } catch (e) {
        console.error("Error in processLiveMatches:", e);
    }
}

// Helper to fetch collection as ID Map
async function fetchCollectionMap(env, path) {
    const url = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/${path}?pageSize=300&key=${env.FIREBASE_API_KEY}`;
    try {
        const res = await fetch(url);
        if (!res.ok) return {};
        const data = await res.json();
        if (!data.documents) return {};

        const map = {};
        data.documents.forEach(doc => {
            const id = doc.name.split('/').pop();
            const fields = doc.fields;
            let points = 0;
            if (fields.fantasyPoints) {
                if (fields.fantasyPoints.doubleValue) points = parseFloat(fields.fantasyPoints.doubleValue);
                else if (fields.fantasyPoints.integerValue) points = parseInt(fields.fantasyPoints.integerValue);
            }
            map[id] = { fantasyPoints: points };
        });
        return map;
    } catch (e) {
        return {};
    }
}

function extractPlayerStats(matchData) {
    let stats = [];

    if (matchData.batsman || matchData.bowler) {
        (matchData.batsman || []).forEach(b => {
            stats.push({
                playerId: (b.id || b.playerId || '0').toString(),
                name: b.name || 'Unknown',
                team: b.team || 'Unknown',
                isBatting: true,
                runs: parseInt(b.runs || 0),
                balls: parseInt(b.balls || 0),
                fours: parseInt(b.fours || 0),
                sixes: parseInt(b.sixes || 0),
                isOut: b.dismissal ? true : false
            });
        });

        (matchData.bowler || []).forEach(b => {
            let existing = stats.find(p => p.playerId === (b.id || b.playerId || '0').toString());
            if (!existing) {
                existing = {
                    playerId: (b.id || b.playerId || '0').toString(),
                    name: b.name || 'Unknown',
                    team: b.team || 'Unknown',
                    isBatting: false
                };
                stats.push(existing);
            }
            existing.wickets = parseInt(b.wickets || 0);
            existing.overs = parseFloat(b.overs || 0);
            existing.maidens = parseInt(b.maidens || 0);
            existing.runsConceded = parseInt(b.runs || 0);
        });
    }

    return stats;
}

async function updateLeaderboard(matchId, env) {
    // Placeholder
    // console.log(`Leaderboard update requested for ${matchId}`);
}

async function handleRefreshMatches(env, request) {
    try {
        console.log('🔄 Refresh triggered');

        // 1. Check Rate Limit / Cache (30 Minutes)
        // Unless ?force=true is passed
        const url = new URL(request.url);
        const force = url.searchParams.get('force') === 'true';

        if (!force) {
            const cachedMatches = await getFromFirestore('matches', env);
            if (cachedMatches.length > 0) {
                // Find most recent update
                const lastUpdate = cachedMatches.reduce((max, m) => Math.max(max, m.lastUpdated || 0), 0);
                const diffMins = (Date.now() - lastUpdate) / (1000 * 60);

                if (diffMins < 30) {
                    console.log(`✨ Serving cached matches (Age: ${diffMins.toFixed(1)} mins)`);
                    return jsonResponse({
                        success: true,
                        cached: true,
                        total_matches: cachedMatches.length,
                        message: `Served from Cache (Next refresh in ${(30 - diffMins).toFixed(0)} mins). Use ?force=true to override.`
                    });
                }
            }
        }

        console.log('⚡ Cache expired or Forced. Calling RapidAPI...');
        const matches = await fetchFromRapidAPI('/cricket-schedule', env);
        if (!matches || matches.length === 0) {
            return jsonResponse({ success: false, message: 'No matches found from API' });
        }
        await saveToFirestore('matches', matches, env);
        return jsonResponse({
            success: true,
            total_matches: matches.length,
            message: `Refreshed ${matches.length} matches from API.`
        });
    } catch (error) {
        return jsonResponse({ success: false, error: error.message });
    }
}

async function handleGetMatches(env) {
    try {
        const matches = await getFromFirestore('matches', env);
        return jsonResponse({ success: true, matches });
    } catch (error) {
        return jsonResponse({ success: false, error: error.message });
    }
}

async function handleGetScorecard(matchId, env) {
    try {
        const scorecard = await fetchFromRapidAPI(`/scorecard?matchId=${matchId}`, env);
        if (scorecard) {
            // Optional: Save to Firestore if needed, or just return proxy
            // await saveToFirestore(`scorecards`, { id: matchId, ...scorecard }, env);
            return jsonResponse({ success: true, scorecard });
        }
        return jsonResponse({ success: false, message: 'Scorecard not found' });
    } catch (error) {
        return jsonResponse({ success: false, error: error.message });
    }
}

async function handleGetSquads(matchId, env) {
    try {
        if (!matchId) return jsonResponse({ success: false, error: 'matchId required' });

        // RapidAPI endpoint: /get-squad
        const data = await fetchFromRapidAPI(`/get-squad?matchId=${matchId}`, env);

        if (data) {
            return jsonResponse(data); // Pass through exact structure to Flutter
        }
        return jsonResponse({ success: false, message: 'Squad not found' });
    } catch (error) {
        return jsonResponse({ success: false, error: error.message });
    }
}

async function fetchFromRapidAPI(endpoint, env, retryCount = 0) {
    let targetEndpoint = endpoint;
    const isProbe = retryCount > 0;
    if (endpoint.includes('matches') && !isProbe) {
        targetEndpoint = lastWorkingMatchEndpoint || '/matches/list';
    }
    const host = env.RAPID_API_HOST || 'free-cricbuzz-cricket-api.p.rapidapi.com';
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
            console.error(`❌ RapidAPI Error: ${response.status} ${response.statusText}`);
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
            console.log("⚠️ No matches parsed from API. Raw Keys:", Object.keys(data));
        }

        return matches; // Always return array

    } catch (error) {
        console.error('❌ Parse error:', error);
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
            console.error(`❌ Firestore Save Error: ${e.message}`);
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

export function jsonResponse(data, status = 200) {
    return new Response(JSON.stringify(data), {
        status,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
}