
const { execSync } = require('child_process');
const fs = require('fs');

// CONFIG
const API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const API_HOST = 'cricbuzz-cricket.p.rapidapi.com';

// 1. Get Upcoming Matches
console.log("🔍 Fetching Upcoming Matches from D1...");
const matchesCmd = `npx wrangler d1 execute DB --remote --command "SELECT id, series_id, title FROM matches WHERE status = 'Upcoming'" --json`;
const squadsCmd = `npx wrangler d1 execute DB --remote --command "SELECT match_id, json_array_length(team_a_roster) as len FROM match_squads" --json`;

function runCommand(cmd) {
    try {
        return execSync(cmd, { encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] }); // Pipe stderr to ignore update logs
    } catch (e) {
        // console.error("Command Failed:", e.message);
        return "[]";
    }
}

async function main() {
    try {
        const matchesJson = runCommand(matchesCmd);
        const squadsJson = runCommand(squadsCmd);

        // Parse JSON (Wrangler returns array of results)
        // Handle potential parsing errors if output has extra text
        const safeParse = (str) => {
            try {
                // Find start of JSON array
                const start = str.indexOf('[');
                const end = str.lastIndexOf(']');
                if (start === -1 || end === -1) return [];
                return JSON.parse(str.substring(start, end + 1));
            } catch (e) { console.error("Parse Error", e); return []; }
        };

        const matchesRaw = safeParse(matchesJson);
        const squadsRaw = safeParse(squadsJson);

        const matches = (matchesRaw[0]?.results || []);
        const squads = (squadsRaw[0]?.results || []);

        console.log(`✅ Found ${matches.length} Upcoming Matches.`);
        console.log(`✅ Found ${squads.length} Existing Squads.`);

        const squadsMap = new Map();
        squads.forEach(s => squadsMap.set(String(s.match_id), s.len));

        const toSync = [];
        for (const m of matches) {
            const len = squadsMap.get(String(m.id));
            if (!len || len < 10) {
                toSync.push(m);
            }
        }

        console.log(`⚠️ Matches Needing Sync: ${toSync.length}`);

        for (const m of toSync) {
            console.log(`🔄 Syncing ${m.id} (${m.title}) Series: ${m.series_id}...`);
            await syncMatch(m);
            await new Promise(r => setTimeout(r, 1000)); // 1 sec delay safety
        }

        console.log("🎉 Manual Sync Complete!");

    } catch (e) {
        console.error("Script Error:", e);
    }
}

async function syncMatch(match) {
    if (!match.series_id) {
        console.error(`❌ Missing Series ID for ${match.id}`);
        return;
    }

    const url = `https://${API_HOST}/series/v1/${match.series_id}/squads`;

    try {
        const resp = await fetch(url, {
            headers: {
                'x-rapidapi-key': API_KEY,
                'x-rapidapi-host': API_HOST
            }
        });

        if (!resp.ok) {
            console.error(`❌ API Error for ${match.id}: ${resp.status}`);
            return;
        }

        const data = await resp.json();
        // FIND SQUADS FOR TEAMS
        // API returns { squads: [ { squadId, teamId, squadType, player: [] } ] }
        // We need to map team IDs from D1? Or just take what's there?
        // Wait, match has team_a_id and team_b_id? No, we queried minimal.
        // Let's assume we fetch FULL rosters.

        // Better: Get team names/ids from match? 
        // We will just store ALL squads found in this series response that match the match?
        // No, series squad list has ALL teams in series.
        // We need team IDs.

        // FETCH MATCH DETAILS TO GET ID
        const detailCmd = `npx wrangler d1 execute DB --remote --command "SELECT team_a_id, team_b_id FROM matches WHERE id=${match.id}" --json`;
        const detailJson = runCommand(detailCmd);
        const details = JSON.parse(detailJson)[0]?.results?.[0];

        if (!details) {
            console.error(`❌ Could not get details for ${match.id}`);
            return;
        }

        const t1Id = details.team_a_id;
        const t2Id = details.team_b_id;

        // FILTER API DATA
        let teamA = [];
        let teamB = [];

        if (data.squads) {
            const sqA = data.squads.find(s => String(s.teamId) == String(t1Id) && s.squadType === 'squad'); // 'squad' or 'playingXI'? 'squad' usually.
            const sqB = data.squads.find(s => String(s.teamId) == String(t2Id) && s.squadType === 'squad');

            if (sqA && sqA.player) teamA = sqA.player;
            if (sqB && sqB.player) teamB = sqB.player;
        }

        // Also fallback to 'playingXI' if available and squad is empty?

        console.log(`   Found Players: A=${teamA.length}, B=${teamB.length}`);

        if (teamA.length === 0 && teamB.length === 0) {
            console.log("   ❌ Empty Squads in API.");
            return;
        }

        // PREPARE SQL
        // We need to Normalize player data format?
        // D1 expects JSON array of objects { id, name, role, etc }
        // API returns { id, name, imageId, ... }
        // Helper to format
        const format = (list) => list.map(p => ({
            id: p.id,
            name: p.name,
            role: p.role || 'Unknown',
            imageId: p.imageId,
            battingStyle: p.battingStyle,
            bowlingStyle: p.bowlingStyle
        }));

        const jsonA = JSON.stringify(format(teamA)).replace(/'/g, "''"); // Escape single quotes
        const jsonB = JSON.stringify(format(teamB)).replace(/'/g, "''");

        const updateSql = `INSERT INTO match_squads (match_id, team_a_roster, team_b_roster, last_updated, squad_state) VALUES (${match.id}, '${jsonA}', '${jsonB}', ${Date.now()}, 1) ON CONFLICT(match_id) DO UPDATE SET team_a_roster=excluded.team_a_roster, team_b_roster=excluded.team_b_roster, last_updated=excluded.last_updated, squad_state=1`;

        // WRITE TO FILE for execution (to avoid shell escaping hell)
        fs.writeFileSync(`update_${match.id}.sql`, updateSql);

        const execCmd = `npx wrangler d1 execute DB --remote --file update_${match.id}.sql`;
        runCommand(execCmd);
        fs.unlinkSync(`update_${match.id}.sql`);
        console.log(`   ✅ D1 Updated for ${match.id}`);

    } catch (e) {
        console.error(`   ❌ Failed to sync ${match.id}`, e.message);
    }
}

main();
