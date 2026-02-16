// Native Fetch

const WORKER_URL = 'https://fantasy-cricket-api.moremagical4.workers.dev';

async function verify() {
    console.log("🔍 Checking POST /api/join-contest...");
    try {
        const resp = await fetch(`${WORKER_URL}/api/join-contest`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ userId: 'test', contestId: 'test', matchId: 'test', teamId: 'test' })
        });

        console.log(`📡 Status: ${resp.status} ${resp.statusText}`);
        const data = await resp.json();
        console.log("📄 Response:", data);

        if (resp.status === 404) {
            console.error("❌ Endpoint NOT FOUND (404)");
        } else {
            console.log("✅ Endpoint REACHABLE");
        }
    } catch (e) {
        console.error("❌ Error:", e.message);
    }
}
verify();
