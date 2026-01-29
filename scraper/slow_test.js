
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'free-cricbuzz-cricket-api1.p.rapidapi.com';

async function test(ep) {
    console.log(`\nTesting ${ep} on ${host}...`);
    try {
        const response = await fetch(`https://${host}${ep}`, {
            headers: {
                'x-rapidapi-key': RAPID_API_KEY,
                'x-rapidapi-host': host,
                'User-Agent': 'Mozilla/5.0'
            }
        });
        console.log(`Status: ${response.status}`);
        if (response.ok) {
            const data = await response.json();
            console.log('✅ Keys:', Object.keys(data).join(', '));
            if (data.schedules) console.log('Found schedules!');
            return data;
        } else {
            console.log('Body:', await response.text());
        }
    } catch (e) {
        console.log('Error:', e.message);
    }
}

async function main() {
    await test('/live');
    await new Promise(r => setTimeout(r, 10000));
    await test('/matches/upcoming');
    await new Promise(r => setTimeout(r, 10000));
    await test('/matches');
}

main();
