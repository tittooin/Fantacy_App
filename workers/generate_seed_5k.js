const fs = require('fs');

const FILE_PATH = './workers/seed_load_5k.sql';
const BATCH_SIZE = 1000;
const TOTAL_USERS = 5000;


let sql = '-- Seed 5000 Users for Load Test\n';

for (let i = 0; i < TOTAL_USERS; i += 500) {
    sql += 'INSERT OR IGNORE INTO users (id, name, email, deposit_credits, winning_credits) VALUES \n';
    const batch = [];
    for (let j = 0; j < 500; j++) {
        const val = i + j;
        batch.push(`('load_user_${val}', 'Load User ${val}', 'load${val}@test.com', 1000, 0)`);
    }
    sql += batch.join(',\n') + ';\n';
}

fs.writeFileSync(FILE_PATH, sql);
console.log(`Generated ${FILE_PATH} with ${TOTAL_USERS} users.`);
