
// --- Phase 3: Points Engine & Live Score Processing ---

async function processLiveMatches(env) {
    const db = getFirestore(env);
    const apiKey = env.RAPID_API_KEY;
    const apiHost = env.RAPID_API_HOST || 'free-cricbuzz-cricket-api.p.rapidapi.com';

    try {
        // 1. Fetch Live Scores (Confirmed Endpoint from Screenshot)
        // This endpoint returns [] if no matches are live.
        console.log(`📡 Fetching Live Scores from /cricket-livescores...`);
        const response = await fetch(`https://${apiHost}/cricket-livescores`, {
            method: 'GET',
            headers: {
                'x-rapidapi-key': apiKey,
                'x-rapidapi-host': apiHost
            }
        });

        if (!response.ok) throw new Error(`API Error: ${response.status}`);
        const data = await response.json();

        // Handle API wrapper
        const liveMatches = data.response || (Array.isArray(data) ? data : []) || [];
        console.log(`Live Matches Found: ${liveMatches.length}`);

        // DEBUG: Save raw structure if we have data (Discovery Mode)
        if (liveMatches.length > 0) {
            console.log("💾 Saving raw match data for debugging/schema discovery...");
            await saveToFirestore('system', {
                id: 'debug_last_live_response',
                timestamp: new Date().toISOString(),
                data: liveMatches[0]
            }, env);
        } else {
            // If no live matches, we might want to update the match list anyway 
            // to ensure "Upcoming" status is correct.
            // await pollAndSaveMatches(env); // Optional: Enable if you want list updates too
        }

        for (const match of liveMatches) {
            // "Best Guess" Parsing Logic
            // We interpret keys based on common API patterns
            const matchId = match.matchId || match.id || match.match_id;
            if (!matchId) continue;

            console.log(`Processing Match ID: ${matchId}`);

            // Extract stats using our best-guess extractor
            const playerStatsList = extractPlayerStats(match);
            console.log(`Extracted stats for ${playerStatsList.length} players`);

            // Calculate Points & Update Firestore
            const batchPromises = playerStatsList.map(stats => {
                const fantasy = calculateFantasyPoints(stats);
                return saveToFirestore(`matches/${matchId}/players`, {
                    id: stats.playerId.toString(), // Doc ID
                    ...stats,
                    fantasyPoints: fantasy.points,
                    fantasyBreakdown: fantasy.breakdown,
                    lastUpdated: new Date().toISOString()
                }, env);
            });

            await Promise.all(batchPromises);

            // Update Leaderboard (Simple Total)
            await updateLeaderboard(matchId, env);
        }

    } catch (e) {
        console.error("Error in processLiveMatches:", e);
    }
}

// Generic Stat Extractor (Discovery Mode)
function extractPlayerStats(matchData) {
    let stats = [];

    // Adapter 1: Root level 'batsman' and 'bowler' arrays (Common in some endpoints)
    if (matchData.batsman || matchData.bowler) {
        (matchData.batsman || []).forEach(b => {
            stats.push({
                playerId: (b.id || b.playerId || '0').toString(),
                name: b.name || 'Unknown',
                team: b.team || 'Unknown',
                isBatting: true,
                runs: parseInt(b.runs || 0),
                balls: parseInt(b.balls || 0),
                fours: parseInt(b.fours || 0),
                sixes: parseInt(b.sixes || 0),
                isOut: b.dismissal ? true : false
            });
        });

        (matchData.bowler || []).forEach(b => {
            let existing = stats.find(p => p.playerId === (b.id || b.playerId || '0').toString());
            if (!existing) {
                existing = {
                    playerId: (b.id || b.playerId || '0').toString(),
                    name: b.name || 'Unknown',
                    team: b.team || 'Unknown',
                    isBatting: false
                };
                stats.push(existing);
            }
            existing.wickets = parseInt(b.wickets || 0);
            existing.overs = parseFloat(b.overs || 0);
            existing.maidens = parseInt(b.maidens || 0);
            existing.runsConceded = parseInt(b.runs || 0);
        });
    }

    // Adapter 2: "scorecard" object (Our target if we find it)
    else if (matchData.scorecard) {
        // Placeholder for when we know the structure
    }

    // Adapter 3: "score" object with innings
    else if (matchData.score) {
        // Placeholder
    }

    return stats;
}

// Leaderboard Recalculation (Placeholder)
async function updateLeaderboard(matchId, env) {
    // In a real implementation, we would:
    // 1. Fetch all users who joined a contest for this match
    // 2. Fetch their teams
    // 3. Sum points of players in their team
    // 4. Update leaderboard collection
    // For now, we just log
    console.log(`Leaderboard update requested for ${matchId}`);
}
