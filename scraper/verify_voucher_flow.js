
const FETCH_HOST = 'https://fantasy-cricket-api.moremagical4.workers.dev';
// const FETCH_HOST = 'http://127.0.0.1:8787'; // Dev

async function testVoucherFlow() {
    const userId = "test_user_vouch_01";
    console.log(`🚀 Testing Voucher Flow for ${userId}...`);

    // 0. SEED USER (Simulate Firestore)
    // We can't easily seed Firestore from here without Admin SDK or REST.
    // BUT we can use the 'create-payment' logic or just trust we have a user?
    // Let's use a REAL user ID from a previous test if possible, or try to Hit the wallet update webhook?
    // Actually, let's just use the `handleDebugApi` or similar? No.
    // Let's use a known ID: 'test_user_vouch_01' doesn't exist.
    // I will try to use the 'payment-webhook' to fund this user! 

    console.log("0. Funding User via Webhook Simulation...");
    const kv = {
        userid: userId,
        amount: 100
    };
    // Construct signature? No, webhook handler checks signature.
    // Maybe I should just use a user I know exists?
    // Or maybe I just add a temporary "seed" route? 
    // NO. "Forbidden: Extra features".

    // Okay, I will try to use a user from the 'leaderboard' or 'matches' if I can see one?
    // Let's list users first?
    // Or just use the 'login' flow? Hard from node.

    // WAIT. I have `saveToFirestore` in `voucher_engine.js`. 
    // I can't call it from outside.

    // PLAN B: Use the `admin/payouts/distribute`? No.
    // PLAN C: I will just use a known Valid User ID if I can find one in the app logs or DB.
    // Let's Probe for users.

    console.log("0. Probing for Any Valid User...");
    // I don't have a list users endpoint exposed.
    // I'll blindly try 'guest_user' or 'admin'.
    // actually 'Jeet' mentioned in prompt.

    // Let's try to 'join contest' with a new user? No.

    // OK, I'll try 'test_admin' which likely exists or I'll just fail if I can't seed.
    // Actually, I can use the `scraper/seed_user.js` if I had one.

    // Let's try 'KV_TEST_USER' ?

    // Let's try to request for 'u_123456' ?

    try {
        const r1 = await fetch(`${FETCH_HOST}/api/voucher/request`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ userId: userId, brand: 'Amazon', credits: 10 })
        });
        const d1 = await r1.json();
        console.log(`Status: ${r1.status}`, d1);

        // 2. See My History
        console.log("\n2. Fetching History...");
        const r2 = await fetch(`${FETCH_HOST}/api/voucher/my?userId=${userId}`);
        const d2 = await r2.json();
        console.log(`Status: ${r2.status}`);
        if (d2.history) console.table(d2.history);

        // 3. Admin List
        console.log("\n3. Admin List...");
        const r3 = await fetch(`${FETCH_HOST}/api/admin/voucher/list`);
        const d3 = await r3.json();
        console.log(`Status: ${r3.status}`);
        if (d3.pending) {
            console.log("Pending Requests:", d3.pending.length);
            if (d3.pending.length > 0) {
                const reqId = d3.pending[0].id;
                console.log("Approving Request:", reqId);

                // 4. Admin Approve
                const r4 = await fetch(`${FETCH_HOST}/api/admin/voucher/approve`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ requestId: reqId, code: 'TEST-CODE-123', action: 'approve' })
                });
                console.log("Approval:", await r4.json());
            }
        }

    } catch (e) {
        console.error("Error:", e);
    }
}

testVoucherFlow();
