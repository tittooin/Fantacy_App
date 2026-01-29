
// workers/webhook_handler.js
import { getFromFirestore, saveToFirestore } from './index.js'; // Assuming we export these or moving them to shared

/**
 * Handles Cashfree Payment Webhook
 * @param {Request} request 
 * @param {Object} env 
 */
export async function handleCashfreeWebhook(request, env) {
    try {
        const signature = request.headers.get('x-webhook-signature'); // Verify this!
        const timestamp = request.headers.get('x-webhook-timestamp');
        const bodyText = await request.text();

        // TODO: Implement Strict Signature Verification here using env.CASHFREE_SECRET_KEY
        // verifySignature(timestamp, bodyText, signature, env.CASHFREE_SECRET_KEY);

        const data = JSON.parse(bodyText);

        /* 
           Cashfree Payload Structure (Type: PAYMENT_SUCCESS_WEBHOOK)
           data: {
             data: {
               order: { order_id: "...", order_amount: 10, ... },
               payment: { payment_status: "SUCCESS", ... },
               customer_details: { ... }
             },
             type: "PAYMENT_SUCCESS_WEBHOOK"
           }
        */

        if (data.type === 'PAYMENT_SUCCESS_WEBHOOK' || data.type === 'PAYMENT_SUCCESS') {
            const orderId = data.data.order.order_id;
            const amount = data.data.order.order_amount;
            // Customer ID is often in customer_details, or we can look up the transaction by orderId

            // 1. Fetch the transaction to get UserId (and ensure we process only once)
            // We need to import 'getFromFirestore' or stick code in index.js.
            // For now, I'll write the logic assuming we can run DB ops.
            // Since module imports are tricky with mixed logic in index.js, 
            // I will recommend moving DB helpers to 'firebase_utils.js' later.
            // For now, I will return the "Action" to be taken, and index.js executes it.

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
        console.error("Webhook Error", e);
        return { action: 'ERROR', error: e.message };
    }
}
