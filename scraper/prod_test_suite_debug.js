const axios = require('axios');

// CONFIG
const API_BASE = 'https://fantasy-cricket-api.moremagical4.workers.dev';
const MATCH_ID = '124920';
const USER_ID = 'test_verifier_001';

async function runSuite() {
    console.log(`🚀 STARTING FULL SYSTEM VERIFICATION [Match: ${MATCH_ID}]`);
    console.log(`👤 User: ${USER_ID}\n`);

    const report = [];
    const log = (screen, action, exp, act, err) => {
        report.push({ screen, action, exp, act, err });
        console.log(`[${screen}] ${action}: ${err ? 'KX FAIL' : '✅ PASS'}`);
        if (err) console.error(`   Error: ${err}`);
    };

    try {
        // --- PHASE 1: TEAM CREATION ---

        // 1. Fetch Squad
        let squad = {};
        try {
            const res = await axios.get(`${API_BASE}/api/squads?matchId=${MATCH_ID}`);
            squad = res.data;

            console.log("Raw Squad Response Keys:", Object.keys(squad));
            if (squad.error) console.log("❌ SQUAD API ERROR:", squad.error);

            const teamA = squad.teamA || [];
            console.log(`TeamA Length: ${teamA.length}`);
            if (teamA.length > 0) console.log("Sample:", JSON.stringify(teamA[0]));

            const normalize = (r) => {
                if (!r) return 'BAT';
                r = r.toUpperCase();
                if (r.includes('WK')) return 'WK';
                if (r.includes('BAT')) return 'BAT';
                if (r.includes('BOWL')) return 'BOWL';
                if (r.includes('ALL') || r.includes('AR')) return 'AR';
                return 'BAT';
            };

            const roles = { WK: 0, BAT: 0, AR: 0, BOWL: 0 };
            const teamB = squad.teamB || [];
            [...teamA, ...teamB].forEach(p => {
                const role = normalize(p.role);
                roles[role] = (roles[role] || 0) + 1;
            });

            const hasAllRoles = roles.WK > 0 && roles.BAT > 0 && roles.AR > 0 && roles.BOWL > 0;
            const hasCredits = teamA.every(p => p.credits > 0);

            log('Create Team', 'Fetch Squad', 'WK, BAT, AR, BOWL visible',
                hasAllRoles ? 'All Roles Present' : `Missing Roles: ${JSON.stringify(roles)}`,
                hasAllRoles ? null : 'Missing Roles');

            log('Create Team', 'Check Credits', 'Credits > 0',
                hasCredits ? 'Credits Valid' : 'Some Credits 0',
                hasCredits ? null : 'Zero Credits Found');

        } catch (e) {
            log('Create Team', 'Fetch Squad', '200 OK', 'Failed', e.message);
        }

        // ... (Keep simpler for now since Phase 1 is blocking) ...

    } catch (critical) {
        console.error("CRITICAL SUITE FAILURE:", critical);
    }
}

runSuite();
