
async function probe() {
    const workerUrl = 'https://fantasy-cricket-api.moremagical4.workers.dev';

    console.log("🔍 Checking D1 Storage (Zero Quota)...");
    try {
        const res = await fetch(`${workerUrl}/api/get-matches`);
        const data = await res.json();

        if (data.success) {
            console.log(`✅ D1 Content: ${data.matches ? data.matches.length : 0} matches stored.`);
            if (data.matches && data.matches.length > 0) {
                // Sort by start time to see if we have future matches
                const list = data.matches;
                const future = list.filter(m => m.startTime > Date.now());
                console.log(`📅 Future Matches: ${future.length}`);

                const live = list.filter(m => m.status === 'Live' || m.status === 'In Progress');
                console.log(`🔴 Live Matches: ${live.length}`);

                console.log("Sample Data:", JSON.stringify(list[0], null, 2));
            }
        } else {
            console.log("❌ D1 Error:", data);
        }
    } catch (e) {
        console.error("❌ Fetch Error:", e);
    }
}

probe();
