/**
 * Test the Cloudflare Worker after fixing the API host
 * Hindi: Fix ke baad worker ko test karte hain
 */

async function testWorker() {
    try {
        console.log('🧪 Testing Cloudflare Worker /api/refresh-matches...\n');

        const response = await fetch('http://127.0.0.1:8787/api/refresh-matches', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        });

        console.log(`Status: ${response.status} ${response.statusText}`);

        const data = await response.json();
        console.log('\nResponse:', JSON.stringify(data, null, 2));

        if (response.ok) {
            console.log('\n✅ SUCCESS! Worker is working correctly!');
            console.log(`📊 Fetched ${data.count || 0} matches`);
        } else {
            console.log('\n❌ ERROR! Worker returned an error');
        }

    } catch (error) {
        console.error('❌ Test failed:', error.message);
    }
}

testWorker();
