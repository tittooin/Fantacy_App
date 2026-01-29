
// Mock calculateFantasyPoints (minimal version)
function calculateFantasyPoints(stats) {
    let points = 0;
    if (stats.isBatting) {
        points += (stats.runs || 0);
        if (stats.runs >= 50) points += 8;
    }
    if (stats.wickets) {
        points += stats.wickets * 25;
    }
    return { points, breakdown: {} };
}

async function testExtraction() {
    const fs = require('fs');
    const mockData = JSON.parse(fs.readFileSync('scraper/mock_live_payload.json', 'utf8'));

    const liveMatches = mockData.response;
    console.log(`Live Matches: ${liveMatches.length}`);

    for (const match of liveMatches) {
        // Copied from workers/index.js (extractPlayerStats)
        const stats = extractPlayerStats(match);
        console.log("Extracted Stats:", JSON.stringify(stats, null, 2));

        for (const s of stats) {
            const points = calculateFantasyPoints(s);
            console.log(`Player ${s.name}: ${points.points} points`);
        }
    }
}

// Copied logic
function extractPlayerStats(matchData) {
    let stats = [];
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
                existing = { playerId: (b.id || b.playerId || '0').toString(), name: b.name || 'Unknown', isBatting: false };
                stats.push(existing);
            }
            existing.wickets = parseInt(b.wickets || 0);
            existing.overs = parseFloat(b.overs || 0);
            existing.maidens = parseInt(b.maidens || 0);
            existing.runsConceded = parseInt(b.runs || 0);
        });
    }
    return stats;
}

testExtraction();
