
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
            console.log('Keys:', Object.keys(data));
            if (data.typeMatches) console.log('Found typeMatches');
            if (data.matches) console.log('Found matches');
            if (data.schedules) {
                console.log('Found schedules!');
                if (data.schedules.length > 0) {
                    console.log('Schedules[0] Keys:', Object.keys(data.schedules[0]));
                    if (data.schedules[0].matchScheduleList) {
                        console.log('Found matchScheduleList! Count:', data.schedules[0].matchScheduleList.length);
                        console.log('Sample matchInfo:', JSON.stringify(data.schedules[0].matchScheduleList[0].adWrapper?.matchInfo || data.schedules[0].matchScheduleList[0].matchInfo, null, 2));
                    }
                }
            }
        }
    } catch (e) {
        console.log('Error:', e.message);
    }
}

async function main() {
    await test('/matches/list');
    await new Promise(r => setTimeout(r, 2000));
    await test('/matches/upcoming');
    await new Promise(r => setTimeout(r, 2000));
    await test('/matches/recent');
}

main();
