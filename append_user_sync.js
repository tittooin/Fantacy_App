// Test script to append user sync function
const fs = require('fs');

const userSyncFunction = `

// --- USER SYNC HANDLER (Auto-create user in D1) ---
async function handleUserSync(request, env) {
    try {
        const { userId, email, displayName } = await request.json();
        
        if (!userId) {
            return jsonResponse({ success: false, error: 'userId required' }, 400);
        }

        // Check if user already exists
        const existing = await env.DB.prepare("SELECT id FROM users WHERE id = ?").bind(userId).first();
        
        if (existing) {
            return jsonResponse({ success: true, message: 'User already exists', alreadyExists: true });
        }

        // Create new user with default balance
        await env.DB.prepare(\`
            INSERT INTO users (id, email, display_name, deposit_credits, winning_credits, created_at)
            VALUES (?, ?, ?, 0, 0, ?)
        \`).bind(userId, email || '', displayName || 'User', Date.now()).run();

        return jsonResponse({ success: true, message: 'User created successfully', userId });
    } catch (e) {
        console.error("User Sync Error:", e);
        return jsonResponse({ success: false, error: e.message }, 500);
    }
}
`;

fs.appendFileSync('workers/index.js', userSyncFunction);
console.log('✅ User sync function added to workers/index.js');
