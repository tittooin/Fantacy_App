/**
 * Test all possible RapidAPI endpoints
 * Hindi: Sahi endpoint dhoondhne ke liye
 */

const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const RAPID_API_HOST = 'free-cricbuzz-cricket-api.p.rapidapi.com';

const endpoints = [
    '/',
    '/matches',
    '/live',
    '/recent',
    '/upcoming',
    '/schedule',
    '/series',
    '/scorecard',
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

        if (response.ok) {
            const data = await response.json();
            console.log(`✅ ${endpoint} - Status: ${response.status}`);
            console.log(`   Keys: ${Object.keys(data).join(', ')}`);
            return true;
        } else {
            const error = await response.text();
            console.log(`❌ ${endpoint} - Status: ${response.status}`);
            console.log(`   Error: ${error.substring(0, 100)}`);
            return false;
        }
    } catch (error) {
        console.log(`❌ ${endpoint} - Error: ${error.message}`);
        return false;
    }
}

async function testAll() {
    console.log('🔍 Testing RapidAPI Endpoints...\n');

    for (const endpoint of endpoints) {
        await testEndpoint(endpoint);
        console.log('');
        // Wait a bit to avoid rate limiting
        await new Promise(resolve => setTimeout(resolve, 500));
    }
}

testAll();
