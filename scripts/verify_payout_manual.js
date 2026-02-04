// Native Fetch in Node 18+ (No require needed)

// Config
const WORKER_URL = "https://fantasy-cricket-api.moremagical4.workers.dev";
const MATCH_ID = process.argv[2] || "102848"; // Default or Pass ID

async function verifyManualPayout() {
    console.log(`\n🛡️ Verifying Manual Payout Safety Switch for Match: ${MATCH_ID}`);
    console.log(`TARGET: ${WORKER_URL}/api/admin/payouts/distribute`);

    try {
        // 1. Attempt without Method (Should Fail)
        const resGet = await fetch(`${WORKER_URL}/api/admin/payouts/distribute?matchId=${MATCH_ID}`);
        if (resGet.status === 405) console.log("✅ Safety Check 1: GET Request Blocked (Method Not Allowed)");
        else console.log("❌ Safety Check 1 Failed:", resGet.status);

        // 2. Attempt with POST (Should Trigger)
        console.log("👉 Triggering Manual Payout (POST)...");
        const resPost = await fetch(`${WORKER_URL}/api/admin/payouts/distribute`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ matchId: MATCH_ID })
        });

        const data = await resPost.json();
        console.log("📡 Response:", JSON.stringify(data, null, 2));

        if (data.success) {
            console.log("\n✅ SUCCESS: Manual Payout Triggered Successfully!");
            console.log("   (This confirms the Admin Button logic is connected to a working Backend)");
        } else {
            console.log("\n⚠️ RESPONSE: ", data.error || data.message);
        }

    } catch (e) {
        console.error("❌ CRTICAL ERROR:", e.message);
    }
}

verifyManualPayout();
