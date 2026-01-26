/**
 * Discover actual working endpoints on the RapidAPI
 * Hindi: Sahi endpoints dhoondhne ke liye comprehensive test
 */

const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const RAPID_API_HOST = 'free-cricbuzz-cricket-api1.p.rapidapi.com';

// Common cricket API endpoint patterns
const endpoints = [
    // Root paths
    '/',
    '/api',

    // Match-related
    '/matches',
    '/match',
    '/matches/list',
    '/matches/recent',
    '/matches/live',
    '/matches/upcoming',
    '/live',
    '/recent',
    '/upcoming',
    '/schedule',
    '/fixtures',

    // Series
    '/series',
    '/series/list',

    // Scorecard
    '/scorecard',
    '/match/scorecard',

    // Players
    '/players',
    '/player',

    // Teams
    '/teams',
    '/team',
];

async function testEndpoint(endpoint) {
    try {
        const url = `https://${RAPID_API_HOST}${endpoint}`;

        const response = await fetch(url, {
            headers: {
                'x-rapidapi-key': RAPID_API_KEY,
                'x-rapidapi-host': RAPID_API_HOST
            }
        });

        const statusEmoji = response.ok ? '✅' :
            response.status === 429 ? '⚠️' :
                response.status === 404 ? '❌' : '⚡';

        if (response.ok) {
            const data = await response.json();
            const keys = Object.keys(data).slice(0, 5).join(', ');
            console.log(`${statusEmoji} ${response.status} ${endpoint.padEnd(25)} → Keys: ${keys}`);
            return { endpoint, status: response.status, keys: Object.keys(data) };
        } else if (response.status === 429) {
            console.log(`${statusEmoji} ${response.status} ${endpoint.padEnd(25)} → Rate limited (endpoint exists!)`);
            return { endpoint, status: response.status, exists: true };
        } else {
            const text = await response.text();
            const shortError = text.substring(0, 60).replace(/\n/g, ' ');
            console.log(`${statusEmoji} ${response.status} ${endpoint.padEnd(25)} → ${shortError}`);
        }
    } catch (error) {
        console.log(`💥 ERR ${endpoint.padEnd(25)} → ${error.message.substring(0, 50)}`);
    }

    return null;
}

async function main() {
    console.log('🔍 Discovering RapidAPI Endpoints...');
    console.log('Host:', RAPID_API_HOST);
    console.log('='.repeat(80));
    console.log('');

    const workingEndpoints = [];

    for (const endpoint of endpoints) {
        const result = await testEndpoint(endpoint);
        if (result) {
            workingEndpoints.push(result);
        }
        // Small delay to avoid rate limiting
        await new Promise(resolve => setTimeout(resolve, 400));
    }

    console.log('\n' + '='.repeat(80));
    console.log('📊 SUMMARY:');
    console.log('='.repeat(80));

    if (workingEndpoints.length > 0) {
        console.log('\n✅ Working endpoints found:');
        workingEndpoints.forEach(ep => {
            console.log(`   ${ep.endpoint} (${ep.status})`);
            if (ep.keys) {
                console.log(`      Keys: ${ep.keys.join(', ')}`);
            }
        });
    } else {
        console.log('\n❌ No working endpoints found!');
        console.log('   This might indicate:');
        console.log('   1. API subscription issue');
        console.log('   2. Rate limit exceeded');
        console.log('   3. API key invalid');
    }
}

main();
