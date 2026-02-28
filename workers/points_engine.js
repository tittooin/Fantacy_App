
/**
 * Informational Stats Metrics Engine
 * Supports Multiple Formats: T20, ODI, TEST, T10
 */

const METRICS_CONFIG = {
    'T20': {
        run: 1,
        boundary: 1, // Four = 4 runs + 1 bonus = 5
        six: 2,      // Six = 6 runs + 2 bonus = 8
        half_century: 0,
        century: 0,
        duck: 0,
        wicket: 25,
        lbw_bowled: 0,
        three_wickets: 0,
        four_wickets: 0,
        five_wickets: 0,
        maiden: 0,
        catch: 8,
        stump: 0,
        runout: 0
    },
    'ODI': {
        run: 1,
        boundary: 1,
        six: 2,
        half_century: 0,
        century: 0,
        duck: 0,
        wicket: 25,
        lbw_bowled: 0,
        four_wickets: 0,
        five_wickets: 0,
        maiden: 0,
        catch: 8,
        stump: 0,
        runout: 0
    },
    'TEST': {
        run: 1,
        boundary: 1,
        six: 2,
        half_century: 0,
        century: 0,
        duck: 0,
        wicket: 25,
        lbw_bowled: 0,
        four_wickets: 0,
        five_wickets: 0,
        maiden: 0,
        catch: 8,
        stump: 0,
        runout: 0
    }
};

export function calculateStatsMetrics(stats, format = 'T20') {
    let metricsPoints = 0;
    let breakdown = {};

    // 1. Select Config (Default to T20 if unknown)
    const rules = METRICS_CONFIG[format] || METRICS_CONFIG['T20'];

    // --- BATTING ---
    if (stats.runs > 0) {
        const runPoints = stats.runs * rules.run;
        metricsPoints += runPoints;
        breakdown.runs = runPoints;
    }

    if (stats.fours > 0) {
        const fourBonus = stats.fours * rules.boundary;
        metricsPoints += fourBonus;
        breakdown.fours = fourBonus;
    }

    if (stats.sixes > 0) {
        const sixBonus = stats.sixes * rules.six;
        metricsPoints += sixBonus;
        breakdown.sixes = sixBonus;
    }

    // Milestones
    if (stats.runs >= 100) {
        metricsPoints += rules.century;
        breakdown.century = rules.century;
    } else if (stats.runs >= 50) {
        metricsPoints += rules.half_century;
        breakdown.half_century = rules.half_century;
    }

    // Duck
    if (stats.isOut && stats.runs === 0 && (stats.role === 'Batsman' || stats.role === 'Allrounder')) {
        metricsPoints += rules.duck; // duck value is negative in config
        breakdown.duck = rules.duck;
    }

    // --- BOWLING ---
    if (stats.wickets > 0) {
        const wicketPoints = stats.wickets * rules.wicket;
        metricsPoints += wicketPoints;
        breakdown.wickets = wicketPoints;
    }

    if (stats.lbwOrBowled > 0) {
        const bonus = stats.lbwOrBowled * rules.lbw_bowled;
        metricsPoints += bonus;
        breakdown.lbw_bowled = bonus;
    }

    // 3/4/5 Wicket Haul (Highest Tier)
    if (stats.wickets >= 5) {
        metricsPoints += rules.five_wickets;
        breakdown.five_wickets = rules.five_wickets;
    } else if (stats.wickets >= 4) {
        metricsPoints += rules.four_wickets;
        breakdown.four_wickets = rules.four_wickets;
    } else if (stats.wickets >= 3) {
        metricsPoints += rules.three_wickets;
        breakdown.three_wickets = rules.three_wickets;
    }

    if (stats.maidens > 0) {
        const maidenPoints = stats.maidens * rules.maiden;
        metricsPoints += maidenPoints;
        breakdown.maidens = maidenPoints;
    }

    // --- FIELDING ---
    if (stats.catches > 0) {
        const catchPoints = stats.catches * rules.catch;
        metricsPoints += catchPoints;
        breakdown.catches = catchPoints;
    }

    if (stats.stumpings > 0) {
        const stumpingPoints = stats.stumpings * rules.stump;
        metricsPoints += stumpingPoints;
        breakdown.stumpings = stumpingPoints;
    }

    if (stats.runOuts > 0) {
        const runOutPoints = stats.runOuts * rules.runout;
        metricsPoints += runOutPoints;
        breakdown.run_outs = runOutPoints;
    }

    return {
        stats: metricsPoints,
        breakdown: breakdown,
        format_used: format
    };
}

/**
 * Automates Points Sync for a Match
 */
// --- SERIES WHITELIST (API SAVER - Points) ---
function isPrioritySeries(seriesName) {
    if (!seriesName) return false;
    const s = seriesName.toUpperCase();

    // STRICT ALLOWED LIST (User Defined)
    // 1. ICC Events
    if (s.includes('WORLD CUP')) return true;
    if (s.includes('T20 WORLD CUP')) return true;
    if (s.includes('CHAMPIONS TROPHY')) return true;
    if (s.includes('ASIA CUP')) return true;

    // 2. Major Leagues
    if (s.includes('IPL') || s.includes('INDIAN PREMIER')) return true;
    if (s.includes('PSL') || s.includes('PAKISTAN SUPER')) return true;
    if (s.includes('BBL') || s.includes('BIG BASH')) return true;
    if (s.includes('THE HUNDRED')) return true;
    if (s.includes('WPL') || s.includes('WOMEN\'S PREMIER')) return true;

    // 3. Reject Everything Else
    return false;
}

/**
 * Automates Points Sync for a Match
 * Optimization Update: 
 * - Only syncs 'Live' matches
 * - Only syncs 'Upcoming' matches if start_time is within 20 mins (Pre-toss checks)
 * - Strict Time Window: start_time <= now <= start_time + 8 hours
 * - Strict Whitelist: Only Major Leagues
 */
export async function syncMatchMetricsToD1(matchId, env) {
    const API_LOCK_ACTIVE = true;
    if (API_LOCK_ACTIVE) {
        console.log(`[API_LOCK_ACTIVE] Points sync skip: ${matchId}`);
        return 0;
    }
    console.log("STATS_METRICS_V5"); // Version: Compliance Patch

    // 1. Fetch match details to validate Time Window
    const match = await env.DB.prepare("SELECT status, start_time, title FROM matches WHERE id = ?").bind(matchId).first();
    if (!match) return 0;

    // WHITELIST CHECK
    if (!isPrioritySeries(match.title)) {
        // console.log(`⏭️ Skipping Points for ${matchId}: Not in Whitelist.`);
        return 0;
    }

    const now = Date.now();
    const startTime = match.start_time;
    const eightHours = 8 * 60 * 60 * 1000;
    const twentyMins = 20 * 60 * 1000;

    // RULE 1: If Status is Completed/Abandoned, SKIP (Unless forced manual sync, handled by caller?)
    // Actually, this function is called by processLivePoints which selects Live/Upcoming.
    // We add a safety check here too.
    if (match.status === 'Completed' || match.status === 'Abandoned') {
        console.log(`⏭️ Skipping ${matchId}: Status is ${match.status}`);
        return 0;
    }

    // RULE 2: Time Window Check
    // Allow if:
    // a) Status is 'Live' AND Time is within 12 hours of start (Safety for stuck Live matches)
    // b) Status is 'Upcoming' AND Time is within 20 mins of start

    const isLiveViable = (match.status === 'Live' && (now < (startTime + 12 * 60 * 60 * 1000))); // 12h safety for Test matches/Rain
    const isUpcomingViable = (match.status === 'Upcoming' && (now > (startTime - twentyMins)));

    if (!isLiveViable && !isUpcomingViable) {
        // console.log(`⏳ Skipping ${matchId}: Outside Sync Window. Status: ${match.status}, Start: ${new Date(startTime).toISOString()}`);
        return 0;
    }

    console.log(`📊 Syncing Informational Stats for Match ${matchId} (Status: ${match.status})...`);
    const apiKey = env.RAPID_API_KEY;
    const apiHost = 'cricbuzz-cricket.p.rapidapi.com';

    try {
        const resp = await fetch(`https://${apiHost}/mcenter/v1/${matchId}/scard`, {
            headers: { 'x-rapidapi-key': apiKey, 'x-rapidapi-host': apiHost }
        });

        if (!resp.ok) throw new Error(`API Error: ${resp.status}`);
        const data = await resp.json();

        // VALIDATION: If match is actually completed in API data, update DB Status
        if (data.status && (data.status.toLowerCase().includes('complete') || data.status.toLowerCase().includes('result'))) {
            console.log(`✅ Match ${matchId} Completed in API. Updating DB Status.`);
            await env.DB.prepare("UPDATE matches SET status = 'Completed' WHERE id = ?").bind(matchId).run();
        }

        const playerStats = extractPlayerStatsFromScorecard(data);
        console.log(`Found stats for ${playerStats.length} players in scorecard.`);

        // --- NEW: Fetch Commentary for real-time feed ---
        let commentary = [];
        try {
            const commResp = await fetch(`https://${apiHost}/mcenter/v1/${matchId}/comm`, {
                headers: { 'x-rapidapi-key': apiKey, 'x-rapidapi-host': apiHost }
            });
            if (commResp.ok) {
                const commData = await commResp.json();
                commentary = (commData.commentaryList || []).slice(0, 20); // Keep last 20 balls
            }
        } catch (commErr) {
            console.error("Failed to fetch commentary:", commErr);
        }

        // Batch Update D1
        const queries = [];
        for (const stats of playerStats) {
            const fantasy = calculateStatsMetrics(stats, 'T20'); // TODO: Detect format from match info
            queries.push(
                env.DB.prepare(`
                    INSERT INTO stats_metrics (match_id, player_id, points, breakdown)
                    VALUES (?, ?, ?, ?)
                    ON CONFLICT(match_id, player_id) DO UPDATE SET
                        points = excluded.points,
                        breakdown = excluded.breakdown
                `).bind(matchId, stats.playerId, fantasy.stats, JSON.stringify(fantasy.breakdown))
            );
        }

        if (queries.length > 0) {
            await env.DB.batch(queries);
            console.log(`✅ Updated Informational Stats for ${queries.length} players in D1.`);
        }

        // --- NEW: Also Update Live Scorecard for UI (Fail-Safe) ---
        try {
            const details = processScorecardData(data);
            await env.DB.prepare(`
                INSERT INTO live_scores (match_id, status_note, team_a_score, team_b_score, current_over, score_details, commentary, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(match_id) DO UPDATE SET
                    status_note = excluded.status_note,
                    team_a_score = excluded.team_a_score,
                    team_b_score = excluded.team_b_score,
                    current_over = excluded.current_over,
                    score_details = excluded.score_details,
                    commentary = excluded.commentary,
                    updated_at = excluded.updated_at
            `).bind(
                matchId,
                details.status,
                details.team1Score,
                details.team2Score,
                details.overs,
                JSON.stringify(details.fullData),
                JSON.stringify(commentary),
                Date.now()
            ).run();
            // console.log(`✅ Updated live_scores for ${matchId}`);
        } catch (scoreErr) {
            console.error("Failed to update live_scores in cron:", scoreErr);
        }

        // --- NEW: Update Playing XI in match_squads (Fix for Missing Lineups) ---
        try {
            if (playerStats.length > 0) {
                await updatePlayingXI(matchId, playerStats, env);
            }
        } catch (xiErr) {
            console.error("Failed to update playing XI:", xiErr);
        }

        return playerStats.length;

    } catch (e) {
        console.error(`Points Sync Failed for ${matchId}:`, e);
        return 0;
    }
}

async function updatePlayingXI(matchId, playerStats, env) {
    // 1. Get current squads
    const squadData = await env.DB.prepare("SELECT team_a_roster, team_b_roster FROM match_squads WHERE match_id = ?").bind(matchId).first();
    if (!squadData) return;

    const rosterA = JSON.parse(squadData.team_a_roster || '[]');
    const rosterB = JSON.parse(squadData.team_b_roster || '[]');

    // 2. Filter Active Players
    const idSet = new Set(playerStats.map(p => String(p.playerId)));

    // Filter Rosters to keep only those in stats.
    // Ensure ID comparison is robust (String vs Number)
    const xiA = rosterA.filter(p => idSet.has(String(p.id)));
    const xiB = rosterB.filter(p => idSet.has(String(p.id)));

    if (xiA.length === 0 && xiB.length === 0) return;

    console.log(`Updating Playing XI for ${matchId}: A=${xiA.length}, B=${xiB.length}`);

    // 3. Update D1
    await env.DB.prepare(`
        UPDATE match_squads 
        SET playing_11_a = ?, playing_11_b = ?
        WHERE match_id = ?
    `).bind(
        JSON.stringify(xiA),
        JSON.stringify(xiB),
        matchId
    ).run();
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

function processScorecardData(data) {
    // Determine structure of response and extract summary
    // data.scorecard -> innings[] -> batsman[], bowler[]...
    // We need simplistic summary: "150/4 (18.2)"

    let status = data.status || ''; // Often just match status string
    let t1Score = '';
    let t2Score = '';
    let overs = '';

    const innings = data.scorecard || [];
    const t1Inning = innings.find(i => i.inningsId === 1 || i.inningsid === 1);
    const t2Inning = innings.find(i => i.inningsId === 2 || i.inningsid === 2);
    // Note: This logic assumes Innings 1 = Team 1. Real logic needs to check team IDs but strict mapping is complex without team metadata.
    // For now, mapping by innings order.

    if (t1Inning) {
        t1Score = `${t1Inning.runs || 0}/${t1Inning.wickets || 0} (${t1Inning.overs || 0})`;
    }
    if (t2Inning) {
        t2Score = `${t2Inning.runs || 0}/${t2Inning.wickets || 0} (${t2Inning.overs || 0})`;
        status = "2nd Innings";
    }

    // Construct "details" object for Frontend (Team 1, Team 2 objects)
    // Updated: Return FULL innings data for Scorecard UI
    const fullData = {
        summary: {
            team1: t1Inning ? { runs: t1Inning.runs, wickets: t1Inning.wickets, overs: t1Inning.overs } : {},
            team2: t2Inning ? { runs: t2Inning.runs, wickets: t2Inning.wickets, overs: t2Inning.overs } : {},
        },
        innings: innings, // Pass full innings array (batsmen, bowlers)
        status: status
    };

    return {
        status: data.status, // Keep original status
        team1Score: t1Score,
        team2Score: t2Score,
        overs: overs,
        fullData: fullData
    };
}
