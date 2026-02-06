
const workerUrl = 'https://fantasy-cricket-api.moremagical4.workers.dev';

async function testEndpoint() {
    console.log(`Fetching from ${workerUrl}/api/get-matches ...`);
    try {
        const resp = await fetch(`${workerUrl}/api/get-matches`);
        console.log(`Status: ${resp.status}`);
        if (resp.ok) {
            const json = await resp.json();
            console.log(`Success: ${json.success}`);
            if (json.matches) {
                console.log(`Matches Found: ${json.matches.length}`);
                if (json.matches.length > 0) {
                    console.log('Sample Match:', JSON.stringify(json.matches[0], null, 2));
                }
            } else {
                console.log('Matches key missing or empty.');
            }
        } else {
            console.log('Error:', await resp.text());
        }
    } catch (e) {
        console.error('Fetch Failed:', e);
    }
}

testEndpoint();
