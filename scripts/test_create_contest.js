// Test script to create a contest in D1
const WORKER_URL = 'https://fantasy-cricket-api.moremagical4.workers.dev';

async function testCreateContest() {
    const testContest = {
        id: 'test-contest-' + Date.now(),
        matchId: '139084',
        entryFee: 49,
        totalSpots: 100,
        prizePool: 4000,
        category: 'Mega Contest',
        isGuaranteed: true,
        isFlexible: false,
        winningBreakdown: [
            { rankStart: 1, rankEnd: 1, amount: 2000 },
            { rankStart: 2, rankEnd: 5, amount: 500 }
        ]
    };

    console.log('🧪 Testing Contest Creation...');
    console.log('Contest Data:', JSON.stringify(testContest, null, 2));

    try {
        const response = await fetch(`${WORKER_URL}/api/admin/contests/create`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(testContest)
        });

        const result = await response.json();

        console.log('\n📊 Response Status:', response.status);
        console.log('📊 Response Body:', JSON.stringify(result, null, 2));

        if (result.success) {
            console.log('\n✅ Contest created successfully!');
            console.log('Contest ID:', testContest.id);

            // Now try to fetch it back
            console.log('\n🔍 Fetching contests for match 139084...');
            const getResponse = await fetch(`${WORKER_URL}/api/contests?matchId=139084`);
            const contests = await getResponse.json();
            console.log('Contests found:', JSON.stringify(contests, null, 2));
        } else {
            console.log('\n❌ Failed to create contest:', result.error);
        }
    } catch (error) {
        console.error('\n❌ Error:', error.message);
    }
}

testCreateContest();
