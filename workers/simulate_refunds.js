import { processAutoRefunds } from './refund_engine.js';

(async () => {
    console.log("--- STARTING REFUND SIMULATION ---");
    // Mock DB
    const dbData = {
        matches: [{ id: 'match1', status: 'Abandoned' }],
        sys_config: new Map(),
        contests: [
            { id: 'c1', match_id: 'match1', entry_fee: 10, status: 'Upcoming', filled_spots: 2 },
            { id: 'c2', match_id: 'match1', entry_fee: 0, status: 'Upcoming', filled_spots: 5 } // Free contest
        ],
        contest_participants: [
            { contest_id: 'c1', user_id: 'userA' },
            { contest_id: 'c1', user_id: 'userA' }, // userA joined twice
            { contest_id: 'c1', user_id: 'userB' },
            { contest_id: 'c2', user_id: 'userA' },
            { contest_id: 'c2', user_id: 'userC' }
        ],
        transactions: []
    };

    const env = {
        DB: {
            prepare: (sql) => ({
                bind: (...args) => ({
                    sql,
                    args,
                    first: async () => {
                        const isSysConfig = sql.includes('SELECT value FROM sys_config WHERE key = ?');
                        if (isSysConfig) {
                            return dbData.sys_config.has(args[0]) ? { value: dbData.sys_config.get(args[0]) } : null;
                        }
                        return null;
                    },
                    all: async () => {
                        if (sql.includes('SELECT id, entry_fee, status')) {
                            return { results: dbData.contests.filter(c => c.match_id === args[0] && !['Refunded', 'Distributed', 'Cancelled'].includes(c.status) && c.filled_spots > 0) };
                        }
                        if (sql.includes('SELECT user_id')) {
                            return { results: dbData.contest_participants.filter(p => p.contest_id === args[0]) };
                        }
                        return { results: [] };
                    },
                    run: async () => {
                        if (sql.includes('INSERT INTO sys_config')) {
                            dbData.sys_config.set(args[0], args[1]);
                        }
                        if (sql.includes("UPDATE contests SET status = 'Refunded'")) {
                            const c = dbData.contests.find(c => c.id === args[0]);
                            if (c) c.status = 'Refunded';
                            console.log(`[DB MOCK] Updated contest ${args[0]} to Refunded`);
                        }
                        return { meta: { changes: 1 } };
                    }
                }),
                all: async () => {
                    if (sql.includes('SELECT id, status')) return { results: dbData.matches.filter(m => ['Abandoned', 'Cancelled', 'No result'].includes(m.status)) };
                    return { results: [] };
                }
            })
        }
    };

    // Correctly define env.DB.batch here, outside of env.DB.prepare
    env.DB.batch = async (statements) => {
        for (const stmt of statements) {
            // we can access the original sql and args because we attached them to the stmt mock
            if (stmt.sql && stmt.sql.includes('INSERT INTO transactions')) {
                const txn = {
                    id: stmt.args[0],
                    user_id: stmt.args[1],
                    type: stmt.args[2],
                    amount: stmt.args[3],
                    contest_id: stmt.args[4],
                    match_id: stmt.args[5]
                };
                dbData.transactions.push(txn);
                console.log(`[DB MOCK] Insert Transaction: user=${txn.user_id}, amount=${txn.amount}, contest=${txn.contest_id}`);
            }
        }
        return [{ meta: { changes: statements.length } }];
    };

    console.log("Running processAutoRefunds...");
    await processAutoRefunds(env);

    console.log("\n--- RESULTS ---");
    console.log("Contests status:");
    for (const c of dbData.contests) {
        console.log(`  ${c.id}: ${c.status}`);
    }
    console.log("Transactions Generated:");
    for (const t of dbData.transactions) {
        console.log(`  ${t.user_id} -> ${t.amount} (Contest: ${t.contest_id})`);
    }
    console.log("Idempotency marker set:", dbData.sys_config.has('refund_done:match1'));

    console.log("\\nRunning again to test idempotency...");
    await processAutoRefunds(env);
    console.log("Transactions Generated (Should be same):", dbData.transactions.length);

})();
