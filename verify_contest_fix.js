// Native fetch used (Node 18+)

const MATCH_ID = '139186';
const WORKER_URL = 'https://fantasy-cricket-api.moremagical4.workers.dev';

async function verify() {
    console.log(`🔍 Checking Contests for Match ${MATCH_ID} on Production...`);

    try {
        const resp = await fetch(`${WORKER_URL}/api/contests?matchId=${MATCH_ID}`);
        if (!resp.ok) throw new Error(`HTTP ${resp.status}`);

        const data = await resp.json();
        console.log("📡 API Response Status:", data.success);

        if (data.contests && data.contests.length > 0) {
            console.log(`✅ SUCCESS: Found ${data.contests.length} contests.`);
            data.contests.forEach(c => {
                console.log(`   - Fee: ₹${c.entryFee} | Spots: ${c.filledSpots}/${c.totalSpots} | Status: ${c.status}`);
            });
        } else {
            console.log("❌ FAIL: No contests returned (Empty Array).");
        }
    } catch (e) {
        console.error("❌ ERROR:", e.message);
    }
}

verify();
