
export async function executeLoadTest(request, env) {
    const start = Date.now();
    const url = new URL(request.url);
    const batchSize = parseInt(url.searchParams.get('batch') || '10');
    const contestId = 'LOAD_TEST_CONTEST_001';

    // STRICT SAFETY CHECK
    // If we are somehow looking at a real contest, ABORT.
    if (!contestId.startsWith('LOAD_TEST')) {
        return new Response("ABORTED: Unsafe Contest ID", { status: 403 });
    }

    const statements = [];
    const userIds = [];

    // 1. Prepare Batch Inserts for test_participants
    for (let i = 0; i < batchSize; i++) {
        const userId = `TEST_USER_${Date.now()}_${Math.random().toString(36).substring(7)}`;
        userIds.push(userId);

        statements.push(env.DB.prepare(`
            INSERT INTO test_participants (id, contest_id, user_id, joined_at)
            VALUES (?, ?, ?, ?)
        `).bind(
            crypto.randomUUID(),
            contestId,
            userId,
            Date.now()
        ));
    }

    // 2. Update test_contests filled_spots
    statements.push(env.DB.prepare(`
        UPDATE test_contests 
        SET filled_spots = filled_spots + ? 
        WHERE id = ?
    `).bind(batchSize, contestId));

    // 3. Execute Batch
    try {
        const results = await env.DB.batch(statements);
        const duration = Date.now() - start;

        return new Response(JSON.stringify({
            success: true,
            message: `Inserted ${batchSize} participants into SANDBOX.`,
            duration_ms: duration,
            users: userIds.slice(0, 3) // sample
        }), { headers: { 'Content-Type': 'application/json' } });

    } catch (e) {
        return new Response(JSON.stringify({ error: e.message }), { status: 500 });
    }
}
