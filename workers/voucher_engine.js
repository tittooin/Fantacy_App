
/**
 * Voucher Redemption Engine (Manual System)
 * Responsibilities:
 * 1. Maintain Voucher Requests in D1
 * 2. Deduct Credits from User Wallet (D1 winning_credits)
 * 3. Admin Approval Logic
 * 
 * STRICTLY NO FIRESTORE WRITES FOR REQUESTS OR WALLET
 * D1 IS MASTER FOR WALLET (deposit_credits + winning_credits)
 */

import { jsonResponse } from './index.js';

// --- USER ENDPOINTS ---

export async function handleVoucherRequest(request, env) {
    if (request.method !== 'POST') return jsonResponse({ error: 'Method Not Allowed' }, 405);

    try {
        const body = await request.json();
        const { userId, brand, credits } = body;

        if (!userId || !brand || !credits) return jsonResponse({ error: 'Missing fields' }, 400);

        // 1. Check Balance in D1 (winning_credits only)
        // We assume user exists in D1. If not, they have 0 balance.
        const user = await env.DB.prepare("SELECT winning_credits FROM users WHERE id = ?").bind(userId).first();

        const currentWinnings = user ? (user.winning_credits || 0) : 0;

        if (currentWinnings < credits) {
            return jsonResponse({ error: 'Insufficient Winning Credits' }, 402);
        }

        // 2. Deduct Winning Credits (D1 Only)
        // We use a transaction or just sequential updates. D1 batch/transaction is better for consistency but simple update is fine for now as per "simple system" rule.
        // Actually, let's verify update success.

        const result = await env.DB.prepare(`
            UPDATE users SET winning_credits = winning_credits - ? 
            WHERE id = ? AND winning_credits >= ?
        `).bind(credits, userId, credits).run();

        if (result.meta.changes === 0) {
            return jsonResponse({ error: 'Deduction failed (Balance changed or User not found)' }, 409);
        }

        // 3. Create Pending Request in D1
        const reqId = `vr_${Date.now()}_${Math.random().toString(36).substring(7)}`;

        await env.DB.prepare(`
            INSERT INTO voucher_requests (id, user_id, brand, credits, status, created_at)
            VALUES (?, ?, ?, ?, 'pending', ?)
        `).bind(reqId, userId, brand, credits, Date.now()).run();

        return jsonResponse({ success: true, message: 'Request Submitted' });

    } catch (e) {
        return jsonResponse({ error: e.message }, 500);
    }
}

export async function handleVoucherUserHistory(userId, env) {
    try {
        const { results } = await env.DB.prepare(`
            SELECT * FROM voucher_requests 
            WHERE user_id = ? 
            ORDER BY created_at DESC
        `).bind(userId).all();

        return jsonResponse({ success: true, history: results });
    } catch (e) {
        return jsonResponse({ error: e.message }, 500);
    }
}

// --- ADMIN ENDPOINTS ---

export async function handleAdminVoucherList(env) {
    try {
        const pending = await env.DB.prepare("SELECT * FROM voucher_requests WHERE status = 'pending' ORDER BY created_at ASC").all();
        const history = await env.DB.prepare("SELECT * FROM voucher_requests WHERE status != 'pending' ORDER BY created_at DESC LIMIT 20").all();

        return jsonResponse({
            success: true,
            pending: pending.results,
            history: history.results
        });
    } catch (e) {
        return jsonResponse({ error: e.message }, 500);
    }
}

export async function handleAdminApproveVoucher(request, env) {
    if (request.method !== 'POST') return jsonResponse({ error: 'Method Not Allowed' }, 405);

    try {
        const body = await request.json();
        const { requestId, code, action } = body; // action: 'approve' or 'reject'

        if (!requestId || !action) return jsonResponse({ error: 'Missing fields' }, 400);

        if (action === 'approve') {
            if (!code) return jsonResponse({ error: 'Voucher Code Required' }, 400);

            await env.DB.prepare(`
                UPDATE voucher_requests 
                SET status = 'approved', voucher_code = ?, approved_at = ?
                WHERE id = ?
             `).bind(code, Date.now(), requestId).run();

            return jsonResponse({ success: true, message: 'Voucher Approved' });
        }
        else if (action === 'reject') {
            // 1. Get Request details
            const req = await env.DB.prepare("SELECT user_id, credits FROM voucher_requests WHERE id = ?").bind(requestId).first();
            if (!req) return jsonResponse({ error: 'Request not found' }, 404);

            // 2. Refund to D1 Winning Credits
            await env.DB.prepare(`
                UPDATE users SET winning_credits = winning_credits + ? WHERE id = ?
            `).bind(req.credits, req.user_id).run();

            // 3. Update Status
            await env.DB.prepare(`
                UPDATE voucher_requests 
                SET status = 'rejected', approved_at = ?
                WHERE id = ?
             `).bind(Date.now(), requestId).run();

            return jsonResponse({ success: true, message: 'Request Rejected & Refunded' });
        }

        return jsonResponse({ error: 'Invalid Action' }, 400);

    } catch (e) {
        return jsonResponse({ error: e.message }, 500);
    }
}
