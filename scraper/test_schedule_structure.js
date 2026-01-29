
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const host = 'free-cricbuzz-cricket-api1.p.rapidapi.com';

async function test() {
    console.log(`Testing /schedule on ${host}...`);
    try {
        const response = await fetch(`https://${host}/schedule`, {
            headers: {
                'x-rapidapi-key': RAPID_API_KEY,
                'x-rapidapi-host': host,
                'User-Agent': 'Mozilla/5.0'
            }
        });
        console.log(`Status: ${response.status}`);
        const data = await response.json();
        console.log('Keys:', Object.keys(data));
        if (data.schedules) {
            console.log('Found schedules! First element keys:', Object.keys(data.schedules[0]));
            if (data.schedules[0].matchScheduleList) {
                console.log('Found matchScheduleList!');
                console.log('Sample match:', JSON.stringify(data.schedules[0].matchScheduleList[0], null, 2));
            }
        }
    } catch (e) {
        console.log('Error:', e.message);
    }
}

test();
