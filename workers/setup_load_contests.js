// Native Fetch used.

const WORKER_URL = 'https://fantasy-cricket-api.moremagical4.workers.dev';
const MATCHES = ['match_load_1', 'match_load_2', 'match_load_3'];
const CATEGORIES = ['Mega Loader', 'Quick 1v1', 'Mid-Range'];

async function setup() {
    console.log("Creating Matches...");
    // We assume matches might need to be created in DB or use existing mock logic.
    // For now, let's just create contests. The API doesn't strictly validate match existence in `contests` table foreign key unless enforced?
    // Schema has `match_id` but no strict Foreign Key to a `matches` table? 
    // Actually `matches` table exists. Let's insert them first via SQL if needed, or assume API handles it?
    // Admin create contest API usually takes matchId.
    // Let's create contests directly.

    // Contests Configuration
    const configs = [
        { suffix: 'mega', spots: 5000, fee: 10, cat: 'Mega Loader' }, // 1 Huge contest
        { suffix: 'mid', spots: 100, fee: 50, cat: 'Mid-Range' },     // Multiple of these
        { suffix: 'h2h', spots: 2, fee: 100, cat: 'Quick 1v1' }       // Many of these
    ];

    for (const matchId of MATCHES) {
        console.log(`Setting up for ${matchId}...`);

        // 1. Mega Contest (Capacity 5000)
        await createContest(`${matchId}_mega`, matchId, 5000, 10, 'Mega Loader');

        // 2. 10 Mid-Range Contests (Capacity 100)
        for (let i = 0; i < 10; i++) {
            await createContest(`${matchId}_mid_${i}`, matchId, 100, 50, 'Mid-Range');
        }

        // 3. 50 H2H Contests (Capacity 2)
        for (let i = 0; i < 50; i++) {
            await createContest(`${matchId}_h2h_${i}`, matchId, 2, 100, 'Quick 1v1');
        }
    }
    console.log("Setup Complete.");
}

async function createContest(id, matchId, spots, fee, category) {
    try {
        const res = await fetch(`${WORKER_URL}/api/admin/contests/create`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                id, matchId, entryFee: fee, totalSpots: spots, prizePool: fee * spots * 0.9,
                category, isGuaranteed: true, isFlexible: false, winningBreakdown: []
            })
        });
        const data = await res.json();
        if (data.success) console.log(`Created ${id}`);
        else console.log(`Failed ${id}: ${data.error || data.message}`);
    } catch (e) {
        console.log(`Error creating ${id}: ${e.message}`);
    }
}

setup();
