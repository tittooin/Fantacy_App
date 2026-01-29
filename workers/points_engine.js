/**
 * Fantasy Points Engine
 * Rules:
 * Batting: Run(+1), 4s(+1), 6s(+2), 30(+4), 50(+8), 100(+16), Duck(-2)
 * Bowling: Wicket(+25), Bowled/LBW(+8), Maiden(+12), 3W(+4), 5W(+8)
 * Fielding: Catch(+8), Runout(+12), Stumping(+12)
 * SR (min 10 balls): >170(+6), 150-170(+4), <60(-4)
 * Eco (min 2 overs): <5(+6), 5-6(+4), >10(-6)
 * Captain: 2x, VC: 1.5x
 */

export function calculateFantasyPoints(stats) {
    let points = 0;
    let breakdown = {
        batting: 0,
        bowling: 0,
        fielding: 0,
        bonus: 0,
        economy: 0,
        strikeRate: 0,
        total: 0
    };

    // --- Batting ---
    breakdown.batting += (stats.runs || 0);
    breakdown.bonus += (stats.fours || 0) * 1;
    breakdown.bonus += (stats.sixes || 0) * 2;

    if ((stats.runs || 0) >= 100) breakdown.bonus += 16;
    else if ((stats.runs || 0) >= 50) breakdown.bonus += 8;
    else if ((stats.runs || 0) >= 30) breakdown.bonus += 4;

    // Duck (0 runs, out, played > 0 balls or just out)
    // Assuming 'isOut' is true and runs == 0.
    // Note: Duck applies to batsmen, not bowlers who didn't bat. 
    // We assume parser sets isBatting=true if they came to crease.
    if (stats.isBatting && (stats.runs || 0) === 0 && stats.isOut) {
        breakdown.batting -= 2;
    }

    // Strike Rate (min 10 balls)
    if ((stats.balls || 0) >= 10) {
        const sr = (stats.runs / stats.balls) * 100;
        if (sr > 170) breakdown.strikeRate += 6;
        else if (sr >= 150) breakdown.strikeRate += 4;
        else if (sr < 60) breakdown.strikeRate -= 4;
    }

    // --- Bowling ---
    breakdown.bowling += (stats.wickets || 0) * 25;
    breakdown.bonus += (stats.bowledLbwCount || 0) * 8;
    breakdown.bowling += (stats.maidens || 0) * 12;

    if ((stats.wickets || 0) >= 5) breakdown.bonus += 8;
    else if ((stats.wickets || 0) >= 3) breakdown.bonus += 4;

    // Economy (min 2 overs)
    // Overs are often typically represented as 3.4 (3 overs 4 balls) -> convert to balls
    // Or parser passes 'oversBowled' as float.
    // Let's assume stats.overs is a number like 3.5
    if ((stats.overs || 0) >= 2) {
        const eco = (stats.runsConceded || 0) / (stats.overs || 1); // rough calc, parser should give clean eco
        if (eco < 5) breakdown.economy += 6;
        else if (eco >= 5 && eco <= 6) breakdown.economy += 4;
        else if (eco > 10) breakdown.economy -= 6;
    }

    // --- Fielding ---
    breakdown.fielding += (stats.catches || 0) * 8;
    breakdown.fielding += (stats.runouts || 0) * 12;
    breakdown.fielding += (stats.stumpings || 0) * 12;

    // --- Total Base ---
    points = breakdown.batting + breakdown.bowling + breakdown.fielding + breakdown.bonus + breakdown.economy + breakdown.strikeRate;
    breakdown.total = points;

    // --- Multiplier ---
    if (stats.isCaptain) points *= 2;
    else if (stats.isViceCaptain) points *= 1.5;

    return {
        points: Math.round(points), // Ensure integer
        breakdown
    };
}
