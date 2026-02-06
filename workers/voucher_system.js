// Voucher System Worker Endpoints

export async function handleVoucherRedeem(request, env) {
    const { userId, rewardCredits } = await request.json();

    if (!userId || !rewardCredits || rewardCredits < 100) {
        return jsonResponse({ success: false, error: 'Minimum 100 credits required' });
    }

    const voucherCode = generateVoucherCode();
    const voucherId = `v_${Date.now()}_${userId.substring(0, 8)}`;

    try {
        const userDoc = await env.FIRESTORE.collection('users').doc(userId).get();
        const userData = userDoc.data();
        const rewardBalance = userData?.rewardCredits || 0;

        if (rewardBalance < rewardCredits) {
            return jsonResponse({ success: false, error: 'Insufficient reward credits' });
        }

        await env.FIRESTORE.collection('users').doc(userId).update({
            rewardCredits: rewardBalance - rewardCredits
        });

        await env.DB.prepare(`
            INSERT INTO vouchers (id, user_id, code, brand, value, status, created_at)
            VALUES (?, ?, ?, ?, ?, 'active', ?)
        `).bind(voucherId, userId, voucherCode, 'Amazon', rewardCredits, Date.now()).run();

        return jsonResponse({
            success: true,
            voucher: {
                code: voucherCode,
                brand: 'Amazon',
                value: rewardCredits
            }
        });
    } catch (e) {
        console.error('Voucher Error:', e);
        return jsonResponse({ success: false, error: e.message }, 500);
    }
}

export async function handleVoucherList(request, env) {
    const url = new URL(request.url);
    const userId = url.searchParams.get('userId');

    if (!userId) {
        return jsonResponse({ success: false, error: 'userId required' });
    }

    try {
        const result = await env.DB.prepare(`
            SELECT id, code, brand, value, status, created_at, redeemed_at
            FROM vouchers
            WHERE user_id = ?
            ORDER BY created_at DESC
            LIMIT 50
        `).bind(userId).all();

        return jsonResponse({
            success: true,
            vouchers: result.results || []
        });
    } catch (e) {
        console.error('Voucher List Error:', e);
        return jsonResponse({ success: false, error: e.message }, 500);
    }
}

function generateVoucherCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let code = '';
    for (let i = 0; i < 12; i++) {
        code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
}

function jsonResponse(data, status = 200) {
    return new Response(JSON.stringify(data), {
        status,
        headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        }
    });
}
