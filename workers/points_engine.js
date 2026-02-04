
/**
 * Fantasy Points Engine
 * Supports Multiple Formats: T20, ODI, TEST, T10
 */

const POINTS_CONFIG = {
    'T20': {
        run: 1,
        boundary: 1,
        six: 2,
        half_century: 8,
        century: 16,
        duck: -2,
        wicket: 25,
        lbw_bowled: 8,
        four_wickets: 8,
        five_wickets: 16,
        maiden: 8,
        catch: 8,
        stump: 12,
        runout: 6
    },
    'ODI': {
        // Placeholder for ODI rules
        run: 1,
        boundary: 1,
        six: 2,
        half_century: 4, // ODI usually has lower bonus
        century: 8,
        duck: -3,
        wicket: 25,
        lbw_bowled: 8,
        four_wickets: 4,
        five_wickets: 8,
        maiden: 4,
        catch: 8,
        stump: 12,
        runout: 6
    },
    'TEST': {
        // Placeholder for TEST rules
        run: 1,
        boundary: 1,
        six: 2,
        half_century: 4,
        century: 8,
        duck: -4,
        wicket: 16,
        lbw_bowled: 8,
        four_wickets: 4,
        five_wickets: 8,
        maiden: 0, // No points for maiden in test usually
        catch: 8,
        stump: 12,
        runout: 6
    }
};

export function calculateFantasyPoints(stats, format = 'T20') {
    let points = 0;
    let breakdown = {};

    // 1. Select Config (Default to T20 if unknown)
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
    if (stats.runs >= 100) {
        points += rules.century;
        breakdown.century = rules.century;
    } else if (stats.runs >= 50) {
        points += rules.half_century;
        breakdown.half_century = rules.half_century;
    }

    // Duck
    if (stats.isOut && stats.runs === 0 && (stats.role === 'Batsman' || stats.role === 'Allrounder')) {
        points += rules.duck; // duck value is negative in config
        breakdown.duck = rules.duck;
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

    // 4/5 Wicket Haul
    if (stats.wickets >= 5) {
        points += rules.five_wickets;
        breakdown.five_wickets = rules.five_wickets;
    } else if (stats.wickets >= 4) {
        points += rules.four_wickets;
        breakdown.four_wickets = rules.four_wickets;
    }

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

    return {
        total: points,
        breakdown: breakdown,
        format_used: format // Helpful for debugging
    };
}
