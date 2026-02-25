/**
 * Refund Engine (Phase 11 - Authoritative Model)
 * Automatically processes refunds for Abandoned/Cancelled matches.
 * 
 * STRICT RULES:
 * 1. Read-only on live state & match rules.
 * 2. Idempotent: Checks refund_done marker.
 * 3. Exact Split Mirror: Reconstructs exact deposit_used/winning_used from original tx.
 * 4. Explicit Direct Wallet Reversal allowed.
 */

export async function processAutoRefunds(env) {
    console.log("🔄 Auto Refund Engine Triggered");

    try {
        const { results: targetMatches } = await env.DB.prepare(`
            SELECT id, status 
            FROM matches 
            WHERE status IN ('Abandoned', 'Cancelled', 'No result')
        `).all();

        if (!targetMatches || targetMatches.length === 0) return;

        for (const match of targetMatches) {
            await processRefundForMatch(env, match.id);
        }

    } catch (e) {
        console.error("❌ Auto Refund Engine Error:", e);
    }
}

async function processRefundForMatch(env, matchId) {
    const markerKey = `refund_done:${matchId}`;
    const markerRow = await env.DB.prepare("SELECT value FROM sys_config WHERE key = ?").bind(markerKey).first();
    if (markerRow) return;

    console.log(`⚠️ Processing authoritative auto-refunds for Match: ${matchId}`);

    const { results: contests } = await env.DB.prepare(`
        SELECT id, entry_fee, status 
        FROM contests 
        WHERE match_id = ? 
        AND status NOT IN ('Refunded', 'Distributed', 'Cancelled')
        AND filled_spots > 0
    `).bind(matchId).all();

    if (!contests || contests.length === 0) {
        await markRefundDone(env, matchId, markerKey);
        return;
    }

    let totalRefundsProcessed = 0;

    for (const contest of contests) {
        if (!contest.entry_fee || contest.entry_fee <= 0) {
            await env.DB.prepare("UPDATE contests SET status = 'Refunded' WHERE id = ?").bind(contest.id).run();
            continue;
        }

        const { results: participants } = await env.DB.prepare(`
            SELECT id, user_id 
            FROM contest_participants 
            WHERE contest_id = ?
        `).bind(contest.id).all();

        if (!participants || participants.length === 0) {
            await env.DB.prepare("UPDATE contests SET status = 'Refunded' WHERE id = ?").bind(contest.id).run();
            continue;
        }

        const txnStatements = [];

        for (const p of participants) {
            if (!p.user_id || !p.id) continue;

            // Look up exact authoritative join transaction by contest_participant_id
            const originalTx = await env.DB.prepare(`
                SELECT deposit_used, winning_used 
                FROM transactions 
                WHERE type = 'contest_join' 
                AND contest_participant_id = ?
                LIMIT 1
            `).bind(p.id).first();

            // If we find the original transaction splits
            if (originalTx) {
                const depositCreditsRefund = originalTx.deposit_used || 0;
                const winningCreditsRefund = originalTx.winning_used || 0;
                const totalRefund = depositCreditsRefund + winningCreditsRefund;

                const refundTxnId = `refund_${contest.id}_${p.user_id}_${crypto.randomUUID()}`;

                // 1. Transaction Mirror Record
                txnStatements.push(
                    env.DB.prepare(`
                        INSERT INTO transactions (id, user_id, type, amount, deposit_used, winning_used, contest_id, contest_participant_id, match_id, created_at, status)
                        VALUES (?, ?, 'CONTEST_REFUND', ?, ?, ?, ?, ?, ?, ?, 'success')
                    `).bind(refundTxnId, p.user_id, totalRefund, depositCreditsRefund, winningCreditsRefund, contest.id, p.id, matchId, Date.now())
                );

                // 2. Authoritative Wallet Column Update
                if (depositCreditsRefund > 0 || winningCreditsRefund > 0) {
                    txnStatements.push(
                        env.DB.prepare(`
                            UPDATE users 
                            SET deposit_credits = deposit_credits + ?,
                                winning_credits = winning_credits + ?
                            WHERE id = ?
                        `).bind(depositCreditsRefund, winningCreditsRefund, p.user_id)
                    );
                }
                totalRefundsProcessed++;
            } else {
                console.log(`⚠️ No original transaction found for participant ${p.id}. Missing mapping or legacy record.`);
            }
        }

        if (txnStatements.length > 0) {
            for (let i = 0; i < txnStatements.length; i += 50) {
                const batch = txnStatements.slice(i, i + 50);
                await env.DB.batch(batch);
            }
        }

        await env.DB.prepare("UPDATE contests SET status = 'Refunded' WHERE id = ?").bind(contest.id).run();
        console.log(`✅ Contest ${contest.id} refunded authoritatively`);
    }

    await markRefundDone(env, matchId, markerKey);
    console.log(`✅ Match ${matchId} auto-refund fully complete. Processed ${totalRefundsProcessed} participant joins.`);
}

async function markRefundDone(env, matchId, markerKey) {
    await env.DB.prepare(`
        INSERT INTO sys_config (key, value, updated_at) 
        VALUES (?, ?, ?)
    `).bind(markerKey, Date.now().toString(), Date.now()).run();
}
