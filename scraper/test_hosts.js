/**
 * Test both API hosts to find the correct one
 * Hindi: Sahi host dhoondhne ke liye dono test karte hain
 */

const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';

const hosts = [
    'free-cricbuzz-cricket-api.p.rapidapi.com',      // Current (without 1)
    'free-cricbuzz-cricket-api1.p.rapidapi.com',     // Original (with 1)
];

const testEndpoints = ['/', '/matches', '/live', '/scorecard'];

async function testHost(host) {
    console.log(`\n🔍 Testing host: ${host}`);
    console.log('='.repeat(60));

    for (const endpoint of testEndpoints) {
        try {
            const url = `https://${host}${endpoint}`;

            const response = await fetch(url, {
                headers: {
                    'x-rapidapi-key': RAPID_API_KEY,
                    'x-rapidapi-host': host
                }
            });

            if (response.ok) {
                const data = await response.json();
                console.log(`✅ ${endpoint} - Status: ${response.status} - Keys: ${Object.keys(data).slice(0, 5).join(', ')}`);
            } else {
                const error = await response.text();
                console.log(`❌ ${endpoint} - Status: ${response.status} - ${error.substring(0, 80)}`);
            }
        } catch (error) {
            console.log(`❌ ${endpoint} - Error: ${error.message}`);
        }

        // Small delay to avoid rate limiting
        await new Promise(resolve => setTimeout(resolve, 300));
    }
}

async function main() {
    console.log('🚀 Testing RapidAPI Hosts...\n');

    for (const host of hosts) {
        await testHost(host);
    }

    console.log('\n✅ Test complete!');
}

main();
