// Test join contest API
const WORKER_URL = 'https://fantasy-cricket-api.moremagical4.workers.dev';

async function testJoinContest() {
    console.log('🧪 Testing Join Contest API...\n');

    const payload = {
        userId: 'test-user-123',
        contestId: 'ff9fa244-0ffd-435f-a656-772083a18d55', // From earlier test
        matchId: '139084',
        teamName: 'Test Team',
        teamId: 'test-team-id-123'
    };

    try {
        const response = await fetch(`${WORKER_URL}/api/join-contest`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        const data = await response.json();

        console.log('📊 Response Status:', response.status);
        console.log('📊 Response Body:', JSON.stringify(data, null, 2));

        if (data.success) {
            console.log('\n✅ Join Contest Successful!');
        } else {
            console.log('\n❌ Join Contest Failed:', data.error);
        }
    } catch (error) {
        console.error('\n❌ Error:', error.message);
    }
}

testJoinContest();
