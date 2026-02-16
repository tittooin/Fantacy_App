const url = 'https://fantasy-cricket-api.moremagical4.workers.dev/test-economy';

async function trigger() {
    console.log(`🚀 Triggering: ${url}`);
    try {
        const response = await fetch(url);
        const data = await response.json();
        console.log("✅ Response:", JSON.stringify(data, null, 2));
    } catch (e) {
        console.error("❌ Error:", e.message);
    }
}

trigger();
