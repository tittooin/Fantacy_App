const url = 'https://fantasy-cricket-api.moremagical4.workers.dev/api/test/load-gen?batch=10';
const TOTAL_REQUESTS = 100; // 100 * 10 = 1000 users

async function runLoad() {
    console.log(`🚀 Starting Spike Load Test (1000 Users) on SANDBOX...`);
    const start = Date.now();
    const promises = [];

    // Spike: Fire all requests rapidly
    for (let i = 0; i < TOTAL_REQUESTS; i++) {
        const p = fetch(url)
            .then(async (res) => {
                if (!res.ok) throw new Error(`HTTP ${res.status}: ${await res.text()}`);
                return res.json();
            })
            .then(d => process.stdout.write('.'))
            .catch(e => process.stderr.write('x'));

        promises.push(p);

        // Small throttle to prevent local network exhaustion, but allow high concurrency
        if (i % 20 === 0) await new Promise(r => setTimeout(r, 50));
    }

    await Promise.all(promises);
    const duration = (Date.now() - start) / 1000;
    console.log(`\n✅ Load Test Completed in ${duration.toFixed(2)}s`);
    console.log(`⚡ Throughput: ${(1000 / duration).toFixed(2)} users/sec`);
}

runLoad();
