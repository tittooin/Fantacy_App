export async function processPlayerStats(env) {
    const logs = [];
    logs.push("📊 Player Stats Engine Started...");

    const apiKey = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
    const apiHost = 'cricbuzz-cricket.p.rapidapi.com';

    try {
        // 1. DISCOVERY: Find Players needing update
        // Criteria: upcoming matches < 48h, stats missing OR older than 7 days
        const now = Date.now();
        const twoDays = 48 * 60 * 60 * 1000;
        const sevenDays = 7 * 24 * 60 * 60 * 1000;

        // Get active match IDs
        const matches = await env.DB.prepare(`
            SELECT id FROM matches 
            WHERE status = 'Upcoming' AND start_time < ?
        `).bind(now + twoDays).all();

        if (!matches.results || matches.results.length === 0) {
            logs.push("✅ No upcoming matches in 48h window.");
            return { processed: 0, logs };
        }

        const matchIds = matches.results.map(m => m.id);

        // Collect Candidate Players from these matches
        // This is a bit expensive, so we limit to 5 matches to prevent timeout
        const targetMatchIds = matchIds.slice(0, 5);
        const placeholders = targetMatchIds.map(() => '?').join(',');

        const squads = await env.DB.prepare(`
            SELECT team_a_roster, team_b_roster FROM match_squads 
            WHERE match_id IN (${placeholders})
        `).bind(...targetMatchIds).all();

        const candidates = new Set();
        for (const row of squads.results) {
            const teamA = JSON.parse(row.team_a_roster || '[]');
            const teamB = JSON.parse(row.team_b_roster || '[]');
            teamA.forEach(p => candidates.add(p.id));
            teamB.forEach(p => candidates.add(p.id));
        }

        // Filter: Check if they exist in player_stats and are fresh
        const candidateArray = Array.from(candidates);
        if (candidateArray.length === 0) {
            logs.push("✅ No players found in upcoming squads.");
            return { processed: 0, logs };
        }

        // We need to check which of these IDs are NOT in player_stats or are OLD
        // Simplest way: Chunk query
        const playersToUpdate = [];

        // Batch Check (Optimization: Check 50 at a time)
        for (let i = 0; i < candidateArray.length; i += 50) {
            const batch = candidateArray.slice(i, i + 50);
            const batchPlaceholders = batch.map(() => '?').join(',');
            const existing = await env.DB.prepare(`
                SELECT player_id, last_updated FROM player_stats 
                WHERE player_id IN (${batchPlaceholders})
            `).bind(...batch).all();

            const existingMap = new Map();
            existing.results.forEach(r => existingMap.set(r.player_id, r.last_updated));

            for (const pid of batch) {
                const lastUpdated = existingMap.get(pid);
                if (!lastUpdated || (now - lastUpdated > sevenDays)) {
                    playersToUpdate.push(pid);
                }
            }
        }

        logs.push(`🔍 Found ${playersToUpdate.length} players needing stats update.`);

        // 2. BATCHING: Select top 10 to process
        const batch = playersToUpdate.slice(0, 10);
        if (batch.length === 0) {
            logs.push("✅ All player stats are up to date.");
            return { processed: 0, logs };
        }

        logs.push(`🚀 Processing Batch: ${batch.join(', ')}`);

        // 3. FETCH & SAVE
        for (const pid of batch) {
            try {
                const url = `https://${apiHost}/stats/v1/player/${pid}`;
                const resp = await fetch(url, {
                    headers: { 'x-rapidapi-key': apiKey, 'x-rapidapi-host': apiHost }
                });

                if (!resp.ok) {
                    logs.push(`❌ Failed to fetch ${pid}: ${resp.status}`);
                    continue;
                }

                const data = await resp.json();

                // 4. CALCULATION
                const { rating, credits } = calculateRating(data);
                const role = normalizeRole(data.role); // Ensure normalization here too

                // 5. SAVE
                await env.DB.prepare(`
                    INSERT INTO player_stats (player_id, fantasy_rating, credits, role_normalized, last_updated)
                    VALUES (?, ?, ?, ?, ?)
                    ON CONFLICT(player_id) DO UPDATE SET
                        fantasy_rating = excluded.fantasy_rating,
                        credits = excluded.credits,
                        role_normalized = excluded.role_normalized,
                        last_updated = excluded.last_updated
                `).bind(pid, rating, credits, role, now).run();

                logs.push(`✅ Saved ${pid}: Rating=${rating}, Credits=${credits}`);

            } catch (e) {
                logs.push(`⚠️ Error processing ${pid}: ${e.message}`);
            }
        }

        return { processed: batch.length, logs };

    } catch (e) {
        console.error("Stats Engine Error:", e);
        return { processed: 0, error: e.message, logs };
    }
}

function calculateRating(data) {
    // Default / Fallback
    let rating = 50.0;
    let credits = 8.5;

    try {
        // Simple Heuristics based on "recentBatting" and "recentBowling" if available
        // Or "bat" / "bowl" career averages

        let impactScore = 0;

        // Batting Impact
        if (data.bat && Array.isArray(data.bat)) {
            const t20 = data.bat.find(x => x.category === 'T20' || x.category === 'T20I');
            if (t20) {
                // Avg runs + (SR / 10)
                const avg = parseFloat(t20.avg || 0);
                const sr = parseFloat(t20.sr || 0);
                impactScore += (avg * 0.5) + (sr * 0.1);
            }
        }

        // Bowling Impact
        if (data.bowl && Array.isArray(data.bowl)) {
            const t20 = data.bowl.find(x => x.category === 'T20' || x.category === 'T20I');
            if (t20) {
                // Wickets * 5 + (10 - Eco) * 2
                const wkt = parseFloat(t20.wickets || 0); // Need to be careful, this is career total
                // Better to use Average/Eco
                const eco = parseFloat(t20.eco || 8.0);
                const avg = parseFloat(t20.avg || 25.0);

                impactScore += (30 - avg) + (10 - eco) * 3;
            }
        }

        // Normalize Impact Score (0 - 100 range roughly)
        if (impactScore < 20) impactScore = 40 + Math.random() * 10; // Floor
        if (impactScore > 100) impactScore = 95;

        rating = parseFloat(impactScore.toFixed(1));

        // Credits (8.0 to 10.5)
        // Map 40-100 to 8.0-10.5
        // 40 -> 8.0
        // 100 -> 10.5
        // Range = 60, CreditRange = 2.5
        // Factor = 2.5 / 60 = 0.0416
        credits = 8.0 + ((rating - 40) * 0.0416);
        credits = Math.min(10.5, Math.max(8.0, credits)); // Clamp
        credits = Math.round(credits * 2) / 2; // Round to nearest 0.5

    } catch (e) {
        // Fallback to ID hash determinism on read-side, but here just save defaults
    }

    return { rating, credits };
}

function normalizeRole(rawRole) {
    if (!rawRole) return 'BAT';
    const r = rawRole.toUpperCase();
    if (r.includes('WK') || r.includes('KEEPER')) return 'WK';
    if (r.includes('ALL') || r.includes('ROUND')) return 'AR';
    if (r.includes('BOWL')) return 'BOWL';
    return 'BAT';
}
