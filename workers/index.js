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
import { handleVoucherRequest, handleVoucherUserHistory, handleAdminVoucherList, handleAdminApproveVoucher } from './voucher_engine.js';
import { syncMatchPointsToD1 } from './points_engine.js';
import { processEconomy } from './economy_engine.js';
import { executeLoadTest } from './load_test_engine.js';
import { processPlayerStats } from './player_stats_engine.js'; // NEW

// ...

// ... (CORS Headers kept same)

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': '*',
};

// ...

export default {
    async scheduled(event, env, ctx) {
        console.log("⏰ Scheduled Event Triggered");
        ctx.waitUntil(processCricketData(env));
        ctx.waitUntil(processLivePoints(env));
        ctx.waitUntil(processLeaderboards(env));
        ctx.waitUntil(processEconomy(env));
        ctx.waitUntil(processPlayerStats(env)); // NEW Background Stats Sync
    },

    async fetch(request, env, ctx) {
        if (request.method === 'OPTIONS') {
            return new Response(null, {
                status: 204,
                headers: {
                    ...corsHeaders,
                    'Access-Control-Max-Age': '86400',
                }
            });
        }
        try {
            const url = new URL(request.url);
            const path = url.pathname.replace(/\/$/, ''); // Normalize: strip trailing slash

            console.log(`Debug Request: ${path}`);

            // 0. CRITICAL: Allow Test Routes immediately (Bypass all checks)
            // if (path === '/test-squad-sync' || path === '/test-squad-sync/') return handleManualSquadSync(env);
            if (path === '/api/test-force-sync') {
                const mid = url.searchParams.get('matchId');
                if (!mid) return new Response("Missing matchId", { status: 400 });
                const count = await syncMatchPointsToD1(mid, env);
                return new Response(`Synced ${count} players for ${mid}`, { status: 200 });
            }
            if (path === '/api/test-squad-sync') {
                const mid = url.searchParams.get('matchId');
                const source = url.searchParams.get('source'); // Optional: SERIES or SCARD
                if (!mid) return new Response("Missing matchId", { status: 400 });
                const result = await syncMatchSquad(mid, env, source);
                return new Response(JSON.stringify(result, null, 2), {
                    status: 200,
                    headers: { 'Content-Type': 'application/json' }
                });
            }


            if (url.pathname === '/api/leaderboard') return await handleGetLeaderboard(request, env);

            // Team API
            if (url.pathname === '/api/teams/save') return await handleSaveTeam(request, env);
            if (url.pathname === '/api/teams/get') return await handleGetTeams(url.searchParams, env);

            // Wallet API (User)
            if (url.pathname === '/api/wallet/balance') {
                const uid = url.searchParams.get('userId');
                if (!uid) return jsonResponse({ error: 'userId required' }, 400);
                return await handleGetWalletBalance(uid.trim(), env);
            }
            if (url.pathname === '/api/wallet/transactions' || url.pathname === '/api/transactions/my') {
                const uid = url.searchParams.get('userId');
                if (!uid) return jsonResponse({ error: 'userId required' }, 400);
                return await handleGetTransactionHistory(uid.trim(), env);
            }
            if (url.pathname === '/api/wallet/withdraw') return await handleWithdrawRequest(request, env);

            // Admin Wallet API (D1 Only)
            if (url.pathname === '/api/admin/withdrawals') return await handleAdminListWithdrawals(request, env);
            if (url.pathname === '/api/admin/payout/status') return await handleAdminUpdateWithdrawalStatus(request, env);
            if (url.pathname === '/api/admin/payout/reward') return await handleAdminIssueReward(request, env);
            if (url.pathname === '/api/admin/user/search') return await handleAdminUserSearch(request, env);
            if (url.pathname === '/api/admin/users') return await handleAdminListUsers(request, env);
            // --- ROOT & COMPLIANCE (For Domain Verification) ---
            if (path === '/' || path === '') return new Response("Fantasy Cricket API - v2.2 (Normalization Fix)", { status: 200 });
            if (path === '/terms' || path === '/terms-and-conditions') return handleStaticPage('terms');
            if (path === '/refund' || path === '/refund-policy' || path === '/cancellation') return handleStaticPage('refund');
            if (path === '/privacy' || path === '/privacy-policy') return handleStaticPage('privacy');
            if (path === '/contact' || path === '/contact-us') return handleStaticPage('contact');

            if (path === '/matches' || path === '/api/get-matches' || path === '/api/matches') return handleGetMatches(env);
            // Refresh manually?
            if (path === '/matches/refresh' || path === '/api/refresh-matches') {
                const matches = await processCricketData(env);
                return jsonResponse({ success: true, message: "Triggered D1 Update", matches: matches });
            }

            // 1. Access Control (Geo-Blocking & VPN Check)
            const clientIP = request.headers.get('CF-Connecting-IP') || '0.0.0.0';
            const country = request.cf?.country || 'XX';

            // ALLOW TEST ROUTES to bypass checks
            if (path === '/test-squad-sync') {
                // Bypass checks for this specific test route
            } else if (path !== '/health' && !path.startsWith('/api/public')) {
                // ... existing checks ...
            }


            if (path === '/api/test/load-gen') {
                return await executeLoadTest(request, env);
            }

            if (path === '/scorecard' || path.startsWith('/api/scorecard')) {
                const matchId = url.searchParams.get('matchId') || path.split('/').pop();
                return handleGetScorecard(matchId, env);
            }

            if (path === '/squads' || path === '/api/squads') return handleGetSquads(url.searchParams.get('matchId'), env, request);

            // --- IMAGE PROXY (CORS Fix for Player Images) ---
            if (path === '/api/player-image' || path === '/player-image') {
                const imageUrl = url.searchParams.get('url');
                if (!imageUrl) {
                    return jsonResponse({ success: false, error: 'Missing url parameter' }, 400);
                }

                try {
                    const imageResp = await fetch(imageUrl, {
                        headers: {
                            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                            'Accept': 'image/*'
                        }
                    });

                    if (!imageResp.ok) {
                        return new Response('Image not found', { status: 404, headers: corsHeaders });
                    }

                    // Return image with CORS headers
                    return new Response(imageResp.body, {
                        headers: {
                            ...corsHeaders,
                            'Content-Type': imageResp.headers.get('Content-Type') || 'image/jpeg',
                            'Cache-Control': 'public, max-age=86400', // Cache for 24 hours
                        }
                    });
                } catch (e) {
                    console.error('Image Proxy Error:', e);
                    return new Response('Failed to fetch image', { status: 500, headers: corsHeaders });
                }
            }


            // --- PAYMENT ROUTES ---
            if (path === '/pay') return handlePaymentRedirect(url.searchParams, env);
            if (path === '/api/create-payment') return handleCreatePayment(request, env);
            if (path === '/api/payment-webhook') return handlePaymentWebhook(request, env);

            // Contest routes moved to section below

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

            // --- ADMIN PARTICIPANT AUDIT ---
            if (path === '/api/admin/match/participants') {
                const matchId = url.searchParams.get('matchId');
                if (!matchId) return jsonResponse({ success: false, error: 'matchId required' }, 400);
                return handleGetMatchParticipants(matchId, env);
            }

            // --- VOUCHER ROUTES ---



            // --- VOUCHER ROUTES ---
            if (path === '/api/voucher/request') return handleVoucherRequest(request, env);
            if (path === '/api/voucher/my') {
                const uid = url.searchParams.get('userId');
                if (!uid) return jsonResponse({ error: 'UserId required' }, 400);
                return handleVoucherUserHistory(uid, env);
            }

            // All routes handled above in consolidated section
            if (path === '/api/debug/all-users') {
                const { results } = await env.DB.prepare("SELECT * FROM users").all();
                return jsonResponse({ users: results });
            }

            // --- USER SYNC ROUTE (Auto-create user in D1) ---
            if (path === '/api/user/sync') {
                return handleUserSync(request, env);
            }

            // --- ADMIN VOUCHER ROUTES ---
            if (path === '/api/admin/voucher/list') return handleAdminVoucherList(env);
            if (path === '/api/admin/voucher/approve') return handleAdminApproveVoucher(request, env);

            // --- CONTEST ROUTES (D1-Only) ---
            if (path === '/api/admin/contests/create') return handleAdminCreateContest(request, env);
            if (path === '/api/contests' || path === '/api/contests/list') {
                const matchId = url.searchParams.get('matchId');
                if (!matchId) return jsonResponse({ success: false, error: 'matchId required' }, 400);
                return handleGetContests(matchId, env);
            }
            if (path === '/api/contests/join' || path === '/api/join-contest') return handleJoinContest(request, env);
            if (path === '/api/contests/joined') {
                const uid = url.searchParams.get('userId');
                if (!uid) return jsonResponse({ error: 'userId required' }, 400);
                return handleGetUserContests(uid.trim(), env);
            }
            if (path === '/api/contest') {
                const contestId = url.searchParams.get('contestId');
                if (!contestId) return jsonResponse({ success: false, error: 'contestId required' }, 400);
                return handleGetContestById(contestId, env);
            }
            // Fix for Flutter App Mismatch (GET /api/contest/:id)
            if (path.startsWith('/api/contest/')) {
                const contestId = path.split('/').pop();
                return handleGetContestById(contestId, env);
            }
            if (path === '/api/user/contests') {
                const userId = url.searchParams.get('userId');
                if (!userId) return jsonResponse({ success: false, error: 'userId required' }, 400);
                return handleGetUserContests(userId, env);
            }

            if (path === '/diag') return handleGlobalDiag(env);
            if (path === '/fantasy-points') return handleGetFantasyPoints(url.searchParams.get('match_id'), env);
            if (path === '/debug-api' || path === '/api/debug-api') return handleDebugApi(env);

            if (path.startsWith('/api/')) {
                return jsonResponse({ success: false, error: `API Route Not Found: ${path}` }, 404);
            }

            // --- Safety Logging for unknown routes ---
            console.log(`⚠️ Unhandled route: ${path} [${request.method}]`);
            return new Response("Fantasy Cricket Worker (D1-Core) - Access Denied", { status: 403, headers: corsHeaders });

        } catch (e) {
            return new Response(`Worker Error: ${e.message}`, { status: 500, headers: corsHeaders });
        }
    },
};

// ... Helper Functions ...

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

        // Save Transaction to D1 (Pending)
        if (result.success && result.transactionData) {
            const t = result.transactionData;
            await env.DB.prepare(`
                INSERT INTO transactions (id, user_id, type, amount, created_at, status)
                VALUES (?, ?, 'deposit', ?, ?, 'pending')
            `).bind(t.id, t.userId, t.amount, Date.now()).run();

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
            const { orderId, amount } = result;

            // Atomic status update to prevent double processing (Race Condition Fix)
            const updateRes = await env.DB.prepare(`
                UPDATE transactions 
                SET status = 'success' 
                WHERE id = ? AND status = 'pending'
            `).bind(orderId).run();

            if (updateRes.meta.changes > 0) {
                // This worker instance won the race
                // 1. Get User ID from this transaction
                const txn = await env.DB.prepare("SELECT user_id FROM transactions WHERE id = ?").bind(orderId).first();
                const userId = txn.user_id;

                // 2. Update User Wallet
                await env.DB.prepare(`
                    UPDATE users SET deposit_credits = deposit_credits + ? WHERE id = ?
                `).bind(amount, userId).run();

                console.log(`✅ Wallet Updated for ${userId}: +${amount}`);
            } else {
                console.log(`⚠️ Transaction ${orderId} already processed or not found.`);
            }
        }
        else if (result.action === 'UPDATE_TRANSACTION_FAILED') {
            await env.DB.prepare(`
                UPDATE transactions SET status = 'failed' WHERE id = ?
            `).bind(result.orderId).run();
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
        const { userId, contestId, matchId, teamName, playerIds, teamId } = body;

        // Rule 9: Always return 200 with structured JSON.
        if (!userId || !contestId || !matchId || !teamId) {
            return jsonResponse({ success: false, error: 'MISSING_FIELDS' }, 200);
        }

        // 1. Fetch User, Contest, and Count in parallel
        const [user, contest, userCount] = await Promise.all([
            env.DB.prepare("SELECT deposit_credits, winning_credits FROM users WHERE id = ?").bind(userId).first(),
            env.DB.prepare("SELECT * FROM contests WHERE id = ?").bind(contestId).first(),
            env.DB.prepare("SELECT COUNT(*) as count FROM contest_participants WHERE match_id = ? AND user_id = ?").bind(matchId, userId).first()
        ]);

        // Rule 1: Contest existence check
        if (!contest) return jsonResponse({ success: false, error: 'CONTEST_NOT_FOUND' }, 200);

        // Rule 2: Contest status must be "upcoming"
        if (contest.status?.toLowerCase() !== 'upcoming') {
            return jsonResponse({ success: false, error: 'CONTEST_ALREADY_STARTED' }, 200);
        }

        // Rule 3: Contest full check
        if (contest.filled_spots >= contest.total_spots) {
            return jsonResponse({ success: false, error: 'CONTEST_FULL' }, 200);
        }

        // Rule 4: User max 20 teams per contest limit
        if (userCount && userCount.count >= 20) {
            return jsonResponse({ success: false, error: 'LIMIT_EXCEEDED_20_TEAMS' }, 200);
        }

        if (!user) return jsonResponse({ success: false, error: 'USER_NOT_FOUND' }, 200);

        // Rule 6: Wallet balance sufficient check
        const deposit = user.deposit_credits || 0;
        const winnings = user.winning_credits || 0;
        const totalBalance = deposit + winnings;
        const entryFee = contest.entry_fee || 0;

        if (totalBalance < entryFee) {
            return jsonResponse({
                success: false,
                error: 'INSUFFICIENT_BALANCE',
                required: entryFee,
                available: totalBalance
            }, 200);
        }

        // Calculate Split Deduction
        let deductDeposit = entryFee;
        let deductWinnings = 0;
        if (deposit < entryFee) {
            deductDeposit = deposit;
            deductWinnings = entryFee - deductDeposit;
        }

        // Rule 7 & 8: Wallet deduction + participant insert atomic transaction + Race protection
        const txnId = `join_${Date.now()}_${userId}`;
        const participationId = crypto.randomUUID();

        const statements = [
            // A. Deduct Wallet (Atomic)
            env.DB.prepare(`
                UPDATE users 
                SET deposit_credits = deposit_credits - ?,
                winning_credits = winning_credits - ?
                WHERE id = ?
            `).bind(deductDeposit, deductWinnings, userId),

            // B. Increment spots (Trigger safeguards overfill)
            env.DB.prepare(`
                UPDATE contests 
                SET filled_spots = filled_spots + 1 
                WHERE id = ?
                `).bind(contestId),

            // C. Insert Join Record
            env.DB.prepare(`
                INSERT INTO contest_participants(id, contest_id, user_id, team_id, match_id, player_ids, team_name, joined_at) 
                VALUES(?, ?, ?, ?, ?, ?, ?, ?)
            `).bind(
                participationId,
                contestId,
                userId,
                teamId,
                contest.match_id || matchId,
                JSON.stringify(playerIds || []),
                teamName || 'User Team',
                Date.now()
            ),

            // D. Log Transaction
            env.DB.prepare(`
                INSERT INTO transactions(id, user_id, type, amount, contest_id, match_id, created_at, status)
                VALUES(?, ?, 'contest_join', ?, ?, ?, ?, 'success')
            `).bind(txnId, userId, entryFee, contestId, matchId, Date.now())
        ];

        try {
            const results = await env.DB.batch(statements);

            // Verify if updates actually happened
            if (results[0].meta.changes === 0) throw new Error('BALANCE_CONCURRENCY_ERROR');
            if (results[1].meta.changes === 0) throw new Error('CONTEST_FULL_RACE_ERROR');

            // Liquidity Engine: Trigger check
            const currentFilled = (contest.filled_spots || 0) + 1;
            const total = contest.total_spots || 0;
            if (total > 0 && (currentFilled / total) >= 0.8) {
                // Fire and forget (or await if critical)
                // We use await to ensure it happens, but wrap in try-catch so it doesn't fail the join
                try { await ensureLiquidity(contest, env); } catch (e) { console.error('Liquidity Error:', e); }
            }

            return jsonResponse({
                success: true,
                message: 'Contest Joined Successfully',
                remainingBalance: totalBalance - entryFee
            }, 200);

        } catch (txnError) {
            console.error("Atomic Join Failed:", txnError);

            // Handle Unique Constraint (Duplicate Join)
            if (txnError.message && txnError.message.includes('SQLITE_CONSTRAINT')) {
                return jsonResponse({
                    success: false,
                    error: 'ALREADY_JOINED',
                    message: 'Team already joined this contest in another thread.'
                }, 200);
            }

            return jsonResponse({
                success: false,
                error: txnError.message || 'JOIN_TRANSACTION_FAILED'
            }, 200);
        }

    } catch (e) {
        console.error("Join Contest Global Error", e);
        return jsonResponse({ success: false, error: 'SERVER_ERROR' }, 200);
    }
}

async function handleAdminCreateContest(request, env) {
    if (request.method !== 'POST') return jsonResponse({ error: 'Method Not Allowed' }, 405);
    try {
        const body = await request.json();
        const { id, matchId, entryFee, totalSpots, prizePool, category, isGuaranteed, isFlexible, winningBreakdown } = body;

        if (!id || !matchId) return jsonResponse({ success: false, error: 'id and matchId required' }, 400);

        // Save to D1
        // We use INSERT OR REPLACE to align with sync logic
        await env.DB.prepare(`
            INSERT OR REPLACE INTO contests(
                id, match_id, entry_fee, total_spots, filled_spots, prize_pool,
                category, is_guaranteed, is_flexible, winning_breakdown, status, created_at
            ) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            `).bind(
            id,
            matchId.toString(),
            entryFee,
            totalSpots,
            0, // filled_spots starts at 0
            prizePool,
            category,
            isGuaranteed ? 1 : 0,
            isFlexible ? 1 : 0,
            JSON.stringify(winningBreakdown || []),
            'Upcoming',
            Date.now()
        ).run();

        console.log(`✅ D1 Contest Created: ${id} for Match ${matchId}`);
        return jsonResponse({ success: true, message: 'Contest Created in D1' });
    } catch (e) {
        console.error("D1 Create Contest Error:", e);
        return jsonResponse({ success: false, error: e.message }, 500);
    }
}

async function handleGetContestById(contestId, env) {
    try {
        const safeId = contestId.trim();
        const contest = await env.DB.prepare(
            "SELECT * FROM contests WHERE id = ?"
        ).bind(safeId).first();

        if (!contest) return jsonResponse({ success: false, error: 'Contest not found' }, 404);

        const formatted = {
            ...contest,
            matchId: contest.match_id,
            entryFee: contest.entry_fee,
            totalSpots: contest.total_spots,
            filledSpots: contest.filled_spots,
            prizePool: contest.prize_pool,
            isGuaranteed: !!contest.is_guaranteed,
            isFlexible: !!contest.is_flexible,
            winningBreakdown: JSON.parse(contest.winning_breakdown || '[]')
        };

        return jsonResponse({ success: true, contest: formatted });
    } catch (e) {
        return jsonResponse({ success: false, error: e.message }, 500);
    }
}

async function handleGetContests(matchId, env) {
    try {
        const safeMatchId = matchId.toString().trim();
        console.log(`🔍 Fetching Contests for MatchID: ${safeMatchId} `);

        // Updated Query: Visibility Mode (Upcoming + Live)
        const { results } = await env.DB.prepare(
            "SELECT * FROM contests WHERE match_id = ? AND status IN ('Upcoming', 'Live') ORDER BY created_at ASC"
        ).bind(safeMatchId).all();

        console.log(`✅ Found ${results ? results.length : 0} contests for ${matchId} from D1`);

        if (!results) return jsonResponse({ success: true, contests: [] });

        // Filter: One Active Contest Per Fee (Liquidity Rule)
        const contestsByFee = {};

        for (const c of results) {
            const fee = c.entry_fee || 0;

            if (!contestsByFee[fee]) {
                contestsByFee[fee] = c; // Initialize
                continue;
            }

            const current = contestsByFee[fee];
            const currentFull = (current.filled_spots || 0) >= (current.total_spots || 0);

            // If selected is full, we always try to replace it with a newer one (c is newer due to ASC sort)
            // If selected is NOT full, we keep it (Fill oldest first)
            if (currentFull) {
                contestsByFee[fee] = c;
            }
        }

        const finalResults = Object.values(contestsByFee);
        // Sort by fee for clean UI
        finalResults.sort((a, b) => (a.entry_fee || 0) - (b.entry_fee || 0));

        // Map D1 boolean/json fields back to expected formats
        const contests = finalResults.map(c => ({
            ...c,
            matchId: c.match_id,
            entryFee: c.entry_fee,
            totalSpots: c.total_spots,
            filledSpots: c.filled_spots,
            prizePool: c.prize_pool,
            isGuaranteed: !!c.is_guaranteed,
            isFlexible: !!c.is_flexible,
            winningBreakdown: JSON.parse(c.winning_breakdown || '[]')
        }));

        return jsonResponse({ success: true, contests });
    } catch (e) {
        console.error("Fetch API Error:", e);
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

async function handleGetMatchParticipants(matchId, env) {
    try {
        const { results } = await env.DB.prepare(`
            SELECT p.user_id, p.team_name, p.match_id, u.email 
            FROM contest_participants p 
            JOIN users u ON p.user_id = u.id 
            WHERE p.match_id = ?
            `).bind(matchId.toString()).all();
        return jsonResponse({ success: true, participants: results });
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
        // 1. Check D1 Cache (FAST READ ONLY)
        const score = await env.DB.prepare('SELECT * FROM live_scores WHERE match_id = ?').bind(matchId).first();

        if (score) {
            return jsonResponse({ success: true, scorecard: score, source: 'D1_CACHE' });
        }

        // 2. Fail Fast if not in DB (No external fetch)
        // Background Cron is responsible for populating this.
        return jsonResponse({ success: false, error: 'Scorecard not available yet', source: 'D1_MISSING' });

    } catch (error) {
        return jsonResponse({ success: false, error: error.message });
    }
}



// --- RUNTIME MERGE & CACHE ---
const SQUAD_CACHE = new Map(); // Simple Memory Cache

async function handleGetSquads(rawMatchId, env, request) {
    try {
        // Normalize Input: "144321" -> 144321
        const matchIdStr = String(rawMatchId || "").trim();
        if (!matchIdStr) return jsonResponse({ success: false, error: 'matchId required' });

        const matchId = Number(matchIdStr); // CAST Input
        const now = Date.now();

        // 1. MEMORY CACHE (TTL 60s) using normalized ID
        if (SQUAD_CACHE.has(matchIdStr)) {
            const cached = SQUAD_CACHE.get(matchIdStr);
            if (now - cached.ts < 60000) {
                return jsonResponse({
                    success: true,
                    source: 'WORKER_MEM_CACHE',
                    ...cached.data
                });
            }
        }

        // 2. FETCH STATIC SQUAD (D1) with STRICT INTEGER CASTING
        // Fix: match_id in DB is REAL (144321.0), input is "144321"
        const d1Squad = await env.DB.prepare(
            "SELECT team_a_roster, team_b_roster, playing_11_a, playing_11_b, last_updated FROM match_squads WHERE CAST(match_id AS INTEGER) = CAST(? AS INTEGER)"
        ).bind(matchId).first();

        // Fetch Team Metadata
        let matchInfo = await env.DB.prepare("SELECT team_a_id, team_b_id FROM matches WHERE CAST(id AS INTEGER) = CAST(? AS INTEGER)").bind(matchId).first();
        const team1Id = matchInfo?.team_a_id || '0';
        const team2Id = matchInfo?.team_b_id || '0';

        if (!d1Squad || !d1Squad.team_a_roster) {
            // FALLBACK DUMMY (Soft Launch Safety)
            return generateDummySquad(matchId, team1Id, team2Id);
        }

        const rawTeamA = JSON.parse(d1Squad.team_a_roster || '[]');
        const rawTeamB = JSON.parse(d1Squad.team_b_roster || '[]');
        const rawXiA = JSON.parse(d1Squad.playing_11_a || '[]');
        const rawXiB = JSON.parse(d1Squad.playing_11_b || '[]');

        // STEP 2: RAW DATA LOG
        console.log("RAW_D1_DATA", rawTeamA.length, rawTeamB.length);

        // 3. COLLECT IDs & FETCH STATS (Batch)
        const allMap = new Map();
        [...rawTeamA, ...rawTeamB, ...rawXiA, ...rawXiB].forEach(p => {
            if (p.id) allMap.set(p.id, p);
        });

        const allIds = Array.from(allMap.keys());

        // Query player_stats for these IDs
        // "WHERE player_id IN (...)"
        // Warning: if > 100 players, chunk it. Usually squads are < 50.
        let statsMap = new Map();

        if (allIds.length > 0) {
            const placeholders = allIds.map(() => '?').join(',');
            const stats = await env.DB.prepare(`
                SELECT player_id, fantasy_rating, credits, role_normalized 
                FROM player_stats WHERE player_id IN (${placeholders})
            `).bind(...allIds).all();

            if (stats.results) {
                stats.results.forEach(s => statsMap.set(s.player_id, s));
            }
        }

        // 4. MERGE & DETERMINISTIC FALLBACK
        const enrich = (p) => {
            const stat = statsMap.get(p.id);
            const pidHash = simpleHash(p.id);

            // Role: Trust backend 'p.role' (from squad_engine strict norm) or override if stats has better?
            // User requirement: "Backend Source of Truth" -> squad_engine already normalizes.
            // But if stats has something, maybe use it? Let's stick to squad_engine role for consistency unless missing.
            const role = p.role || stat?.role_normalized || 'BAT';

            // Credits: Real or Hash
            // Hash: 8.0 + (hash % 10)/10 -> 8.0 to 8.9? No.
            // User Rule: role_base_credit + (hash % 10)/10
            // WK=8.5, BAT=8.5, AR=9.0, BOWL=8.5 (Adjusted for typical fantasy)
            // Let's use user's constants if provided, else reasonable defaults.
            // User said: role_base: WK=55, BAT=50... that's RATING.
            // Credits: role_base_credit... let's deduce.

            let credits = 8.0;
            let rating = 50.0;

            if (stat) {
                credits = stat.credits || 8.0;
                rating = stat.fantasy_rating || 50.0;
            } else {
                // DETERMINISTIC FALLBACK
                // Credits
                const baseCredit = role === 'AR' ? 8.5 : 8.0;
                credits = baseCredit + (pidHash % 6) * 0.5; // 8.0, 8.5, 9.0, 9.5, 10.0, 10.5

                // Rating
                // User: (hash % 40) + role_base
                // WK=55, BAT=50, AR=60, BOWL=52
                let baseRating = 50;
                if (role === 'WK') baseRating = 55;
                if (role === 'AR') baseRating = 60;
                if (role === 'BOWL') baseRating = 52;

                rating = baseRating + (pidHash % 40);
            }

            return {
                id: p.id,
                name: p.name,
                role: role,
                credits: credits,
                fantasy_rating: rating,
                teamId: (p.teamId || (allMap.get(p.id) === p ? team1Id : team2Id)).toString(), // Contextual ID
                teamShortName: p.teamShortName,
                imageUrl: p.imageUrl,
                isCaptain: p.isCaptain || false,
                isWicketKeeper: role === 'WK'
            };
        };

        const finalTeamA = rawTeamA.map(enrich);
        const finalTeamB = rawTeamB.map(enrich);
        const finalXiA = rawXiA.map(enrich);
        const finalXiB = rawXiB.map(enrich);

        // STEP 3: AFTER MAP LOG
        console.log("AFTER_ROLE_MAP", finalTeamA.length + finalTeamB.length);


        // 5. SORT STABLE
        // WK -> BAT -> AR -> BOWL
        // Then ID Asc
        const roleOrder = { 'WK': 1, 'BAT': 2, 'AR': 3, 'BOWL': 4 };
        const sorter = (a, b) => {
            const rA = roleOrder[a.role] || 5;
            const rB = roleOrder[b.role] || 5;
            if (rA !== rB) return rA - rB;
            return a.id.localeCompare(b.id);
        };

        finalTeamA.sort(sorter);
        finalTeamB.sort(sorter);
        finalXiA.sort(sorter);
        finalXiB.sort(sorter);

        // STEP 4: FINAL COUNT LOG
        const allFinal = [...finalTeamA, ...finalTeamB];
        const grouped = { WK: 0, BAT: 0, AR: 0, BOWL: 0 };
        allFinal.forEach(p => grouped[p.role] = (grouped[p.role] || 0) + 1);
        console.log("FINAL_API_PLAYERS", grouped.WK, grouped.BAT, grouped.AR, grouped.BOWL);

        const responseData = {
            teamA: finalTeamA,
            teamB: finalTeamB,
            xiA: finalXiA,
            xiB: finalXiB,
            matchId: matchId,
            team1Id: team1Id,
            team2Id: team2Id
        };

        // Cache It
        SQUAD_CACHE.set(matchId, { ts: now, data: responseData });

        return jsonResponse({
            success: true,
            source: 'D1_RUNTIME_MERGE',
            ...responseData
        });

    } catch (e) {
        console.error('Squad Error:', e);
        return jsonResponse({ success: false, error: 'Internal error: ' + e.message }, 200);
    }
}

function simpleHash(str) {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
        hash = (hash << 5) - hash + str.charCodeAt(i);
        hash |= 0;
    }
    return Math.abs(hash);
}

function generateDummySquad(matchId, t1, t2) {
    // ... (Existing Dummy Logic if needed, or minimal stub)
    return jsonResponse({ success: true, source: 'DUMMY', teamA: [], teamB: [], matchId });
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
        const match = await env.DB.prepare("SELECT status FROM matches WHERE id = ?").bind(parseInt(matchId)).first();
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

async function handleGetWalletBalance(userId, env) {
    try {
        console.log(`D1: Fetching balance for [${userId}]`);
        // 1. Ensure user in D1
        const user = await ensureUserInD1(userId, env);

        if (!user) {
            console.log(`D1: User NOT found for [${userId}] after sync attempt`);
        } else {
            console.log(`D1: Found user, winnings: ${user.winning_credits}`);
        }

        const deposit = user ? (user.deposit_credits || 0) : 0;
        const winnings = user ? (user.winning_credits || 0) : 0;

        return jsonResponse({
            success: true,
            balance: {
                deposit: deposit,
                winnings: winnings,
                total: deposit + winnings
            }
        });
    } catch (e) {
        console.error("D1 Error:", e);
        return jsonResponse({ success: false, error: e.message }, 500);
    }
}

export function jsonResponse(data, status = 200) {
    return new Response(JSON.stringify(data), {
        status,
        headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
            'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0'
        }
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

async function handleGetTransactions(userId, env) {
    try {
        const { results } = await env.DB.prepare(
            "SELECT * FROM transactions WHERE user_id = ? ORDER BY created_at DESC LIMIT 50"
        ).bind(userId).all();

        return jsonResponse({
            success: true,
            transactions: results
        });
    } catch (e) {
        return jsonResponse({ success: false, error: e.message }, 500);
    }
}
async function handleGetUserContests(userId, env) {
    try {
        const { results } = await env.DB.prepare(`
            SELECT cp.*, c.category, c.entry_fee, c.prize_pool, m.title as match_title
            FROM contest_participants cp
            JOIN contests c ON cp.contest_id = c.id
            LEFT JOIN matches m ON cp.match_id = m.id
            WHERE cp.user_id = ?
            ORDER BY cp.joined_at DESC
        `).bind(userId).all();

        return jsonResponse({ success: true, contests: results });
    } catch (e) {
        console.error("D1 Get User Contests Error:", e);
        return jsonResponse({ success: false, error: e.message }, 500);
    }
}



// --- USER SYNC HANDLER (Auto-create user in D1) ---
async function handleUserSync(request, env) {
    try {
        const { userId, email, displayName } = await request.json();

        if (!userId) {
            return jsonResponse({ success: false, error: 'userId required' }, 400);
        }

        // Check if user already exists
        const existing = await env.DB.prepare("SELECT id FROM users WHERE id = ?").bind(userId).first();

        if (existing) {
            return jsonResponse({ success: true, message: 'User already exists', alreadyExists: true });
        }

        // Create new user with default balance
        await env.DB.prepare(`
            INSERT INTO users (id, email, display_name, deposit_credits, winning_credits, joined_at, last_active)
            VALUES (?, ?, ?, 0, 0, ?, ?)
        `).bind(userId, email || '', displayName || 'User', Date.now(), Date.now()).run();

        return jsonResponse({ success: true, message: 'User created successfully', userId });
    } catch (e) {
        console.error("User Sync Error:", e);
        return jsonResponse({ success: false, error: e.message }, 500);
    }
}


async function ensureUserInD1(userId, env) {
    if (!userId) return null;
    return await env.DB.prepare("SELECT * FROM users WHERE id = ?").bind(userId).first();
}

/**
 * Iterates over Live matches and syncs points
 */
async function processLivePoints(env) {
    console.log("🔄 Processing Live Points for all active matches...");
    try {
        const { results: liveMatches } = await env.DB.prepare(
            "SELECT id FROM matches WHERE status = 'Live' OR status = 'Upcoming'" // Also check Upcoming in case of early start
        ).all();

        if (!liveMatches || liveMatches.length === 0) {
            console.log("No live matches to sync points for.");
            return;
        }

        for (const match of liveMatches) {
            await syncMatchPointsToD1(match.id, env);
        }
    } catch (e) {
        console.error("processLivePoints Error:", e);
    }
}


// --- D1 TEAM HANDLERS ---

async function handleSaveTeam(request, env) {
    try {
        const body = await request.json();
        const { id, userId, matchId, teamName, players, captainId, viceCaptainId } = body;

        if (!userId || !matchId || !players) {
            return jsonResponse({ success: false, error: 'Missing required fields' }, 400);
        }

        const finalId = (id && id.toString().trim().length > 0) ? id.toString().trim() : `team_${Date.now()}_${userId}`;
        console.log(`💾 Saving Team. ID: ${finalId}, Name: ${teamName}`);

        const result = await env.DB.prepare(`
            INSERT INTO teams (id, user_id, match_id, team_name, players_json, captain_id, vice_captain_id, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                team_name = excluded.team_name,
                players_json = excluded.players_json,
                captain_id = excluded.captain_id,
                vice_captain_id = excluded.vice_captain_id
        `).bind(
            finalId,
            userId,
            matchId,
            teamName || 'My Team',
            JSON.stringify(players),
            captainId,
            viceCaptainId,
            Date.now()
        ).run();

        console.log("✅ D1 Save Result:", JSON.stringify(result));

        return jsonResponse({ success: true, message: 'Team processed', id: finalId, d1: result });
    } catch (e) {
        console.error("❌ D1 Save Error:", e.message);
        return jsonResponse({ success: false, error: e.message }, 500);
    }
}

async function handleGetTeams(queryParams, env) {
    try {
        const userId = queryParams.get('userId');
        const matchId = queryParams.get('matchId');

        console.log(`🔍 Fetching Teams for User: ${userId}, Match: ${matchId}`);

        let query = "SELECT * FROM teams WHERE user_id = ?";
        let params = [userId];

        if (matchId) {
            query += " AND match_id = ?";
            params.push(matchId);
        }

        const { results } = await env.DB.prepare(query).bind(...params).all();

        const formatted = results.map(t => ({
            id: t.id,
            userId: t.user_id,
            matchId: t.match_id.toString(),
            teamName: t.team_name,
            players: JSON.parse(t.players_json || '[]'),
            captainId: t.captain_id,
            viceCaptainId: t.vice_captain_id,
            totalPoints: t.total_points || 0
        }));

        return jsonResponse({ success: true, teams: formatted });
    } catch (e) {
        return jsonResponse({ success: false, error: e.message }, 500);
    }
}

// --- WALLET: WITHDRAW REQUEST (User) ---
async function handleWithdrawRequest(request, env) {
    if (request.method !== 'POST') return jsonResponse({ error: 'Method Not Allowed' }, 405);
    try {
        const { userId, amount, method, details } = await request.json();
        if (!userId || !amount || !method) return jsonResponse({ success: false, error: 'MISSING_FIELDS' }, 400);

        // 1. Check Winning Balance
        const user = await env.DB.prepare("SELECT winning_credits FROM users WHERE id = ?").bind(userId).first();
        if (!user || user.winning_credits < amount) {
            return jsonResponse({ success: false, error: 'INSUFFICIENT_WINNINGS' }, 200);
        }

        const requestId = `payout_${Date.now()}_${userId}`;

        // 2. Atomic Deduction and Request Insertion
        const statements = [
            env.DB.prepare("UPDATE users SET winning_credits = winning_credits - ? WHERE id = ? AND winning_credits >= ?")
                .bind(amount, userId, amount),
            env.DB.prepare("INSERT INTO payout_requests (id, user_id, amount, method, details, status, created_at) VALUES (?, ?, ?, ?, ?, 'pending', ?)")
                .bind(requestId, userId, amount, method, details || '', Date.now()),
            env.DB.prepare("INSERT INTO transactions (id, user_id, type, amount, created_at, status) VALUES (?, ?, 'withdrawal_request', ?, ?, 'pending')")
                .bind(requestId, userId, amount, Date.now())
        ];

        const results = await env.DB.batch(statements);
        if (results[0].meta.changes === 0) throw new Error('INSUFFICIENT_BALANCE_RACE');

        return jsonResponse({ success: true, message: 'Withdrawal requested' });
    } catch (e) {
        return jsonResponse({ success: false, error: e.message }, 500);
    }
}

// --- ADMIN: WALLET ACTIONS ---
async function handleAdminListWithdrawals(request, env) {
    try {
        const { results } = await env.DB.prepare("SELECT * FROM payout_requests WHERE status = 'pending' ORDER BY created_at ASC").all();
        return jsonResponse({ success: true, withdrawals: results });
    } catch (e) {
        return jsonResponse({ success: false, error: e.message }, 500);
    }
}

async function handleAdminUpdateWithdrawalStatus(request, env) {
    if (request.method !== 'POST') return jsonResponse({ error: 'Method Not Allowed' }, 405);
    try {
        const { requestId, status, note } = await request.json(); // status: approved, rejected
        if (!requestId || !status) return jsonResponse({ success: false, error: 'MISSING_FIELDS' }, 400);

        const pr = await env.DB.prepare("SELECT * FROM payout_requests WHERE id = ?").bind(requestId).first();
        if (!pr) return jsonResponse({ success: false, error: 'REQUEST_NOT_FOUND' }, 404);
        if (pr.status !== 'pending') return jsonResponse({ success: false, error: 'ALREADY_PROCESSED' }, 400);

        if (status === 'approved') {
            const statements = [
                env.DB.prepare("UPDATE payout_requests SET status = 'approved', admin_note = ?, processed_at = ? WHERE id = ? AND status = 'pending'")
                    .bind(note || 'Processed', Date.now(), requestId),
                env.DB.prepare("UPDATE transactions SET status = 'success' WHERE id = ?")
                    .bind(requestId)
            ];
            const results = await env.DB.batch(statements);
            if (results[0].meta.changes === 0) return jsonResponse({ success: false, error: 'ALREADY_PROCESSED_OR_NOT_FOUND' }, 409);
        } else if (status === 'rejected') {
            const statements = [
                env.DB.prepare("UPDATE users SET winning_credits = winning_credits + ? WHERE id = ?").bind(pr.amount, pr.user_id),
                env.DB.prepare("UPDATE payout_requests SET status = 'rejected', admin_note = ?, processed_at = ? WHERE id = ? AND status = 'pending'")
                    .bind(note || 'Rejected by Admin', Date.now(), requestId),
                env.DB.prepare("UPDATE transactions SET status = 'rejected' WHERE id = ?")
                    .bind(requestId)
            ];
            const results = await env.DB.batch(statements);
            if (results[1].meta.changes === 0) {
                return jsonResponse({ success: false, error: 'ALREADY_PROCESSED' }, 409);
            }
        }

        return jsonResponse({ success: true, message: `Status updated to ${status}` });
    } catch (e) {
        return jsonResponse({ success: false, error: e.message }, 500);
    }
}

// --- MANUAL TRIGGERS ---
async function handleManualSquadSync(env) {
    console.log("🛠️ Manual Squad Sync Triggered...");
    try {
        const { processSquads } = require('./squad_engine.js');
        const result = await processSquads(env);
        return jsonResponse({ success: true, result });
    } catch (e) {
        return new Response("Manual Sync Failed: " + e.message, { status: 500 });
    }
}

async function handleAdminIssueReward(request, env) {
    if (request.method !== 'POST') return jsonResponse({ error: 'Method Not Allowed' }, 405);
    try {
        const { userId, amount, note } = await request.json();
        if (!userId || !amount) return jsonResponse({ success: false, error: 'MISSING_FIELDS' }, 400);

        await env.DB.prepare("UPDATE users SET winning_credits = winning_credits + ? WHERE id = ?")
            .bind(amount, userId).run();

        const txnId = `reward_${Date.now()}_${userId}`;
        await env.DB.prepare("INSERT INTO transactions (id, user_id, type, amount, created_at, status) VALUES (?, ?, 'reward', ?, ?, 'success')")
            .bind(txnId, userId, amount, Date.now()).run();

        return jsonResponse({ success: true, message: 'Reward issued' });
    } catch (e) {
        return jsonResponse({ success: false, error: e.message }, 500);
    }
}

async function handleAdminUserSearch(request, env) {
    const url = new URL(request.url);
    const email = url.searchParams.get('email');
    if (!email) return jsonResponse({ success: false, error: 'Email required' }, 400);

    try {
        const user = await env.DB.prepare("SELECT id, name, email FROM users WHERE email = ?").bind(email).first();
        if (!user) return jsonResponse({ success: false, message: 'User not found' });
        return jsonResponse({ success: true, user });
    } catch (e) {
        return jsonResponse({ success: false, error: e.message }, 500);
    }
}

async function ensureLiquidity(sourceContest, env) {
    // 1. Check if a non-full contest with same match_id and entry_fee already exists
    // Optimized: Also check if this contest ALREADY has a child (parent_id check)
    // To prevent race conditions, we rely on the UNIQUE constraint on parent_id.
    // But first, let's see if ANY open contest exists.
    const { results } = await env.DB.prepare(`
        SELECT id FROM contests 
        WHERE match_id = ? 
        AND entry_fee = ? 
        AND status = 'Upcoming' 
        AND filled_spots < total_spots 
        AND id != ?
        LIMIT 1
    `).bind(sourceContest.match_id, sourceContest.entry_fee, sourceContest.id).all();

    if (results && results.length > 0) {
        return; // Liquidity exists
    }

    // 2. Clone the contest
    // We try to insert with parent_id = sourceContest.id
    // If another thread already did this for sourceContest.id, it will fail (UNIQUE constraint).
    // This guarantees EXACTLY ONE child per parent.
    const newContestId = crypto.randomUUID();

    try {
        await env.DB.prepare(`
            INSERT INTO contests (
                id, match_id, entry_fee, total_spots, filled_spots, prize_pool, 
                status, created_at, winning_breakdown, is_guaranteed, is_flexible, is_private, 
                parent_id
            )
            VALUES (?, ?, ?, ?, 0, ?, 'Upcoming', ?, ?, ?, ?, ?, ?)
        `).bind(
            newContestId,
            sourceContest.match_id,
            sourceContest.entry_fee,
            sourceContest.total_spots,
            sourceContest.prize_pool,
            Date.now(),
            sourceContest.winning_breakdown, // Copy JSON string
            sourceContest.is_guaranteed,
            sourceContest.is_flexible,
            0, // Force public
            sourceContest.id // This is the PARENT ID (Unique Constraint enforces 1 child)
        ).run();

        console.log(`Liquidity Engine: Spawned new contest ${newContestId} (Parent: ${sourceContest.id})`);
    } catch (e) {
        // If UNIQUE constraint failed, it means another thread already created the child.
        // We can safely ignore this error.
        if (e.message && e.message.includes('UNIQUE constraint failed')) {
            console.log(`Liquidity Race Avoided: Child for ${sourceContest.id} already exists.`);
        } else {
            console.error("Liquidity Create Error:", e);
        }
    }
}

async function handleAdminListUsers(request, env) {
    try {
        const { results } = await env.DB.prepare("SELECT id, name, email, deposit_credits, winning_credits, joined_at FROM users ORDER BY joined_at DESC LIMIT 200").all();
        return jsonResponse({ success: true, users: results });
    } catch (e) {
        return jsonResponse({ success: false, error: e.message }, 500);
    }
}
