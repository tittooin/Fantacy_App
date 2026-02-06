
// workers/webhook_handler.js
import { getFromFirestore, saveToFirestore } from './index.js'; // Assuming we export these or moving them to shared

// Helper to verify signature (Web Crypto API for Cloudflare Workers)
async function verifySignature(ts, body, signature, secret) {
    if (!ts || !signature || !secret) throw new Error("Missing verification headers/config");

    // 1. Check Timestamp Age (Replay Attack Prevention)
    const now = Math.floor(Date.now() / 1000); // Current Time in Seconds

    // Cashfree sends x-webhook-timestamp in MILLISECONDS
    const webhookTimeMs = parseInt(ts, 10);
    const webhookTimeSeconds = Math.floor(webhookTimeMs / 1000);

    if (Math.abs(now - webhookTimeSeconds) > 300) { // 5 minutes tolerance
        console.error(`Timestamp Expired: Now ${now}, Hook ${webhookTimeSeconds}`);
        throw new Error("Webhook Timestamp expired");
    }

    // 2. Compute HMAC
    const data = ts + body;
    const encoder = new TextEncoder();
    const keyData = encoder.encode(secret);
    const msgData = encoder.encode(data);

    const cryptoKey = await crypto.subtle.importKey(
        "raw", keyData, { name: "HMAC", hash: "SHA-256" },
        false, ["sign"]
    );

    const sigBuf = await crypto.subtle.sign("HMAC", cryptoKey, msgData);

    // 3. Convert to Base64
    let binary = '';
    const bytes = new Uint8Array(sigBuf);
    const len = bytes.byteLength;
    for (let i = 0; i < len; i++) {
        binary += String.fromCharCode(bytes[i]);
    }
    const computedSig = btoa(binary);

    // 4. Compare
    if (computedSig !== signature) {
        throw new Error(`Signature Mismatch: Computed ${computedSig} vs Header ${signature}`);
    }
}

/**
 * Handles Cashfree Payment Webhook
 * @param {Request} request 
 * @param {Object} env 
 */
export async function handleCashfreeWebhook(request, env) {
    try {
        const signature = request.headers.get('x-webhook-signature');
        const timestamp = request.headers.get('x-webhook-timestamp');
        const bodyText = await request.text();

        // STRICT VERIFICATION ENABLED
        console.log(`[Webhook Debug] TS: ${timestamp}, Sig: ${signature ? 'Present' : 'Missing'}`);
        // console.log(`[Webhook Debug] Body: ${bodyText}`); // Careful with PII, but need for sig debug

        try {
            await verifySignature(timestamp, bodyText, signature, env.CASHFREE_SECRET_KEY);
            console.log("✅ Webhook Verified/Authentic");
        } catch (sigError) {
            console.error(`[Webhook Sig Failed] ${sigError.message}`);
            // Force Fail for Debugging? No, just log distinct error.
            throw sigError;
        }

        const data = JSON.parse(bodyText);

        /* 
           Cashfree Payload Structure (Type: PAYMENT_SUCCESS_WEBHOOK)
        */

        if (data.type === 'PAYMENT_SUCCESS_WEBHOOK' || data.type === 'PAYMENT_SUCCESS') {
            const orderId = data.data.order.order_id;
            const amount = data.data.order.order_amount;

            return {
                action: 'UPDATE_WALLET',
                orderId: orderId,
                amount: amount,
                status: 'SUCCESS',
                gatewayData: data
            };
        } else if (data.type === 'PAYMENT_FAILED_WEBHOOK') {
            return {
                action: 'UPDATE_TRANSACTION_FAILED',
                orderId: data.data.order.order_id,
                gatewayData: data
            };
        }

        return { action: 'IGNORE', reason: 'Unknown Event Type' };

    } catch (e) {
        console.error("Webhook Verification Error:", e.message);
        // Important: Return 200 to Cashfree but log error internally (or return 400 if you want retry loop)
        // Here we just return action ERROR
        return { action: 'ERROR', error: e.message };
    }
}
