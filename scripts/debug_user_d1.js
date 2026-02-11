
const { execSync } = require('child_process');

const UID = '7x6GkXn2iSX7VU03Tp8jyh6HFXN2'; // From user's screenshot

async function checkUser() {
    console.log(`🔍 Checking D1 for UID: ${UID}`);
    try {
        const output = execSync(`npx wrangler d1 execute fantasy-db --command "SELECT * FROM users WHERE id = '${UID}'" --remote`).toString();
        console.log('--- D1 OUTPUT ---');
        console.log(output);
        console.log('-----------------');

        const config = execSync(`npx wrangler d1 execute fantasy-db --command "SELECT * FROM sys_config" --remote`).toString();
        console.log('\n🔍 Sys Config Check:');
        console.log(config);

    } catch (e) {
        console.error('❌ Error executing D1 command:', e.message);
    }
}

checkUser();
