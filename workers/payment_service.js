
// workers/payment_service.js

/**
 * Creates a payment order via Cashfree API
 * @param {string} userId - User ID
 * @param {number} amount - Amount in INR
 * @param {Object} env - Environment variables
 * @returns {Promise<Object>} - Contains success, paymentLink, or error
 */
export async function createCashfreeOrder(userId, amount, env) {
    try {
        const appId = env.CASHFREE_APP_ID;
        const secretKey = env.CASHFREE_SECRET_KEY;
        const useSandbox = env.CASHFREE_IS_SANDBOX === 'true'; // Set 'true' in wrangler.toml for dev

        if (!appId || !secretKey) {
            throw new Error('Cashfree credentials missing in backend config');
        }

        const baseUrl = useSandbox
            ? 'https://sandbox.cashfree.com/pg/orders'
            : 'https://api.cashfree.com/pg/orders';

        const orderId = `order_${Date.now()}_${userId.substring(0, 5)}`;

        const payload = {
            order_id: orderId,
            order_amount: amount,
            order_currency: 'INR',
            customer_details: {
                customer_id: userId,
                customer_phone: '9999999999', // Required by CF, can be dummy if not collected
                customer_name: `User ${userId.substring(0, 5)}`
            },
            order_meta: {
                return_url: `https://fantacy-app.pages.dev/#/wallet?order_id={order_id}`, // Redirect back to app
                notify_url: `${env.WORKER_URL}/api/payment-webhook` // IMPORTANT: Webhook URL
            }
        };

        const response = await fetch(baseUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'x-client-id': appId,
                'x-client-secret': secretKey,
                'x-api-version': '2023-08-01'
            },
            body: JSON.stringify(payload)
        });

        const data = await response.json();

        if (response.status === 200 || response.status === 201) {
            // Prepare Pending Transaction (saving delegated to index.js)
            const transactionData = await savePendingTransaction(userId, orderId, amount, env);

            return {
                success: true,
                orderId: orderId,
                transactionData: transactionData, // Pass to controller to save
                paymentLink: data.payment_link ? data.payment_link : (data.payment_session_id ? `https://payments-test.cashfree.com/forms/${data.order_id}` : null),
                // Note: Production link structure might differ. API v2023-08-01 returns `payment_link` in response usually.
                // If not, we might need to rely on the return_url strategy completely, but User App expects a link to open.
                // Let's ensure we grab the link.
                raw: data
            };
        } else {
            console.error('Cashfree Error:', data);
            throw new Error(data.message || 'Failed to create order');
        }

    } catch (error) {
        console.error('Create Order Exception:', error);
        return { success: false, error: error.message };
    }
}

async function savePendingTransaction(userId, orderId, amount, env) {
    if (!env.FIREBASE_PROJECT_ID) return; // Skip if no DB

    const transaction = {
        userId: userId,
        type: 'deposit',
        amount: Number(amount),
        status: 'pending',
        orderId: orderId,
        createdAt: new Date().toISOString(),
        gateway: 'cashfree'
    };

    // We return the transaction object to be saved by the main worker script
    // This avoids duplicating Firestore auth logic here.
    return transaction;
}
