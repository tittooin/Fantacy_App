const axios = require('axios');

// --- COPIED LOGIC FROM workers/points_engine.js (with fixes) ---

const POINTS_CONFIG = {
    'T20': {
        run: 1, boundary: 1, six: 2, half_century: 8, century: 16, duck: -2,
        wicket: 25, lbw_bowled: 8, three_wickets: 4, four_wickets: 8, five_wickets: 16,
        maiden: 12, catch: 8, stump: 12, runout: 6
    },
    'ODI': {
        run: 1, boundary: 1, six: 2, half_century: 4, century: 8, duck: -3,
        wicket: 25, lbw_bowled: 8, four_wickets: 4, five_wickets: 8,
        maiden: 4, catch: 8, stump: 12, runout: 6
    },
    'TEST': {
        run: 1, boundary: 1, six: 2, half_century: 4, century: 8, duck: -4,
        wicket: 16, lbw_bowled: 8, four_wickets: 4, five_wickets: 8,
        maiden: 0, catch: 8, stump: 12, runout: 6
    }
};

function calculateFantasyPoints(stats, format = 'T20') {
    let points = 0;
    let breakdown = {};
    const rules = POINTS_CONFIG[format] || POINTS_CONFIG['T20'];

    // --- BATTING ---
    if (stats.runs > 0) {
        const runPoints = stats.runs * rules.run;
        points += runPoints;
        breakdown.runs = runPoints;
    }
    if (stats.fours > 0) {
        const fourBonus = stats.fours * rules.boundary;
        points += fourBonus;
        breakdown.fours = fourBonus;
    }
    if (stats.sixes > 0) {
        const sixBonus = stats.sixes * rules.six;
        points += sixBonus;
        breakdown.sixes = sixBonus;
    }
    // Milestones
    if (stats.runs >= 100) { points += rules.century; breakdown.century = rules.century; }
    else if (stats.runs >= 50) { points += rules.half_century; breakdown.half_century = rules.half_century; }
    // Duck
    if (stats.isOut && stats.runs === 0 && (stats.role === 'Batsman' || stats.role === 'Allrounder')) {
        points += rules.duck; breakdown.duck = rules.duck;
    }

    // --- BOWLING ---
    if (stats.wickets > 0) {
        const wicketPoints = stats.wickets * rules.wicket;
        points += wicketPoints;
        breakdown.wickets = wicketPoints;
    }
    if (stats.lbwOrBowled > 0) {
        const bonus = stats.lbwOrBowled * rules.lbw_bowled;
        points += bonus;
        breakdown.lbw_bowled = bonus;
    }
    // Hauls
    if (stats.wickets >= 5) { points += rules.five_wickets; breakdown.five_wickets = rules.five_wickets; }
    else if (stats.wickets >= 4) { points += rules.four_wickets; breakdown.four_wickets = rules.four_wickets; }
    else if (stats.wickets >= 3) { points += rules.three_wickets; breakdown.three_wickets = rules.three_wickets; }

    if (stats.maidens > 0) {
        const maidenPoints = stats.maidens * rules.maiden;
        points += maidenPoints;
        breakdown.maidens = maidenPoints;
    }

    // --- FIELDING ---
    if (stats.catches > 0) {
        const catchPoints = stats.catches * rules.catch;
        points += catchPoints;
        breakdown.catches = catchPoints;
    }
    if (stats.stumpings > 0) {
        const stumpingPoints = stats.stumpings * rules.stump;
        points += stumpingPoints;
        breakdown.stumpings = stumpingPoints;
    }
    if (stats.runOuts > 0) {
        const runOutPoints = stats.runOuts * rules.runout;
        points += runOutPoints;
        breakdown.run_outs = runOutPoints;
    }

    return { points, breakdown, format_used: format };
}

function extractPlayerStatsFromScorecard(data) {
    const stats = [];
    if (!data || !data.scorecard) return stats;

    data.scorecard.forEach(inning => {
        // --- BATSMEN Parsing ---
        if (inning.batsman && Array.isArray(inning.batsman)) {
            inning.batsman.forEach(b => {
                let existing = stats.find(s => s.playerId === b.id);
                if (!existing) {
                    existing = {
                        playerId: b.id, name: b.name,
                        runs: 0, fours: 0, sixes: 0, wickets: 0, catches: 0,
                        role: 'Batsman'
                    };
                    stats.push(existing);
                }
                existing.runs = parseInt(b.runs || 0);
                existing.fours = parseInt(b.fours || 0);
                existing.sixes = parseInt(b.sixes || 0);
                existing.isOut = b.outDesc !== 'not out' && b.outDec !== 'not out';
                if (b.outdec) existing.isOut = b.outdec !== 'not out';
            });
        }
        else if (inning.batTeamDetails && inning.batTeamDetails.batsmenData) {
            // Fallback for old structure
            Object.values(inning.batTeamDetails.batsmenData).forEach(b => {
                let existing = stats.find(s => s.playerId === b.batId);
                if (!existing) {
                    existing = {
                        playerId: b.batId,
                        name: b.outDesc || 'Batsman',
                        runs: 0, fours: 0, sixes: 0, wickets: 0, catches: 0,
                        role: 'Batsman'
                    };
                    stats.push(existing);
                }
                existing.runs = parseInt(b.runs || 0);
                existing.fours = parseInt(b.fours || 0);
                existing.sixes = parseInt(b.sixes || 0);
                existing.isOut = b.outDesc && b.outDesc !== 'not out';
            });
        }

        // --- BOWLERS Parsing ---
        if (inning.bowler && Array.isArray(inning.bowler)) {
            inning.bowler.forEach(b => {
                let existing = stats.find(s => s.playerId === b.id);
                const bowlStats = {
                    playerId: b.id,
                    wickets: parseInt(b.wickets || 0),
                    maidens: parseInt(b.maidens || 0),
                    overs: parseFloat(b.overs || 0),
                    lbwOrBowled: 0,
                };
                if (existing) { Object.assign(existing, bowlStats); }
                else { stats.push({ ...bowlStats, name: b.name || 'Bowler', role: 'Bowler', runs: 0, fours: 0, sixes: 0, isOut: false, catches: 0 }); }
            });
        }
        else if (inning.bowlTeamDetails && inning.bowlTeamDetails.bowlersData) {
            Object.values(inning.bowlTeamDetails.bowlersData).forEach(b => {
                let existing = stats.find(s => s.playerId === b.bowlerId);
                const bowlStats = {
                    playerId: b.bowlerId,
                    wickets: parseInt(b.wickets || 0),
                    maidens: parseInt(b.maidens || 0),
                    overs: parseFloat(b.overs || 0),
                    lbwOrBowled: 0,
                };
                if (existing) {
                    Object.assign(existing, bowlStats);
                } else {
                    stats.push({ ...bowlStats, name: 'Bowler', role: 'Bowler', runs: 0, fours: 0, sixes: 0, isOut: false, catches: 0 });
                }
            });
        }
    });

    return stats;
}

// --- MAIN EXECUTION ---

async function runDebug(matchId) {
    console.log(`🔍 Debugging Match ID: ${matchId}`);

    // 1. FETCH SCORECARD
    const options = {
        method: 'GET',
        url: `https://cricbuzz-cricket.p.rapidapi.com/mcenter/v1/${matchId}/scard`,
        headers: {
            'x-rapidapi-key': '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee',
            'x-rapidapi-host': 'cricbuzz-cricket.p.rapidapi.com'
        }
    };

    try {
        const resp = await axios.request(options);
        const data = resp.data;

        console.log("✅ API Response Received");

        // 2. EXTRACT STATS
        const playerStats = extractPlayerStatsFromScorecard(data);
        console.log(`📊 Extracted Stats for ${playerStats.length} players`);

        if (playerStats.length > 0) {
            console.log("SAMPLE RAW PLAYER:", JSON.stringify(playerStats[0], null, 2));
        } else {
            console.log("❌ NO PLAYERS EXTRACTED. Dumping Scorecard Keys:");
            if (data.scorecard && data.scorecard[0]) {
                console.log("Scorecard Inning 0 Keys:", Object.keys(data.scorecard[0]));
            }
        }

        // 3. CALCULATE POINTS
        console.log("\n--- POINTS CALCULATION ---");
        playerStats.slice(0, 5).forEach(p => {
            const fantasy = calculateFantasyPoints(p, 'T20');
            console.log(`Player: ${p.name} (${p.playerId}) | Runs: ${p.runs} | Wkts: ${p.wickets || 0} -> Points: ${fantasy.points}`);
            //  console.log("Breakdown:", JSON.stringify(fantasy.breakdown));
        });

        // 4. SQL GENERATION (For Manual Inject)
        console.log("\n--- SQL INJECT ---");
        const squadA = playerStats.filter((_, i) => i % 2 === 0).map(p => ({
            id: String(p.playerId), name: p.name, role: p.role,
            credits: 9.0, teamId: 'T1'
        }));
        const squadB = playerStats.filter((_, i) => i % 2 !== 0).map(p => ({
            id: String(p.playerId), name: p.name, role: p.role,
            credits: 8.5, teamId: 'T2'
        }));

        const sql = `INSERT OR REPLACE INTO match_squads (match_id, team_a_roster, team_b_roster, playing_11_a, playing_11_b, squad_state, last_updated) VALUES (
            '${matchId}',
            '${JSON.stringify(squadA).replace(/'/g, "''")}',
            '${JSON.stringify(squadB).replace(/'/g, "''")}',
            '[]', '[]', 2, ${Date.now()}
        );`;
        const fs = require('fs');
        fs.writeFileSync('scraper/inject.sql', sql);
        console.log("✅ SQL written to scraper/inject.sql");

    } catch (e) {
        console.error("❌ Error:", e.response ? e.response.status : e.message);
    }
}

// Check args
const matchId = process.argv[2] || '101648'; // Default ID
runDebug(matchId);
