// Test script to fetch contests and see the raw response
const WORKER_URL = 'https://fantasy-cricket-api.moremagical4.workers.dev';

async function testFetchContests() {
    console.log('🧪 Testing Contest Fetch for Match 139084...\n');

    try {
        const response = await fetch(`${WORKER_URL}/api/contests?matchId=139084`);
        const data = await response.json();

        console.log('📊 Response Status:', response.status);
        console.log('📊 Response Body:', JSON.stringify(data, null, 2));

        if (data.success && data.contests) {
            console.log(`\n✅ Found ${data.contests.length} contests`);
            data.contests.forEach((contest, index) => {
                console.log(`\nContest ${index + 1}:`);
                console.log('  ID:', contest.id);
                console.log('  Match ID:', contest.match_id, '(type:', typeof contest.match_id + ')');
                console.log('  Entry Fee:', contest.entry_fee);
                console.log('  Category:', contest.category);
                console.log('  Prize Pool:', contest.prize_pool);
                console.log('  Status:', contest.status);
                console.log('  Is Guaranteed:', contest.is_guaranteed);
                console.log('  Is Flexible:', contest.is_flexible);
                console.log('  Winning Breakdown:', contest.winning_breakdown);
            });
        } else {
            console.log('\n❌ No contests found or error:', data.error);
        }
    } catch (error) {
        console.error('\n❌ Error:', error.message);
    }
}

testFetchContests();
