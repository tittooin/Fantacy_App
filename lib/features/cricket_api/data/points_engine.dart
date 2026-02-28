class PointsEngine {
  static double calculateBattingStats({
    required int runs,
    required int fours,
    required int sixes,
    required bool isDuck,
  }) {
    double stats = 0;
    
    // Base Runs
    stats += runs * 1.0;
    
    // Boundaries
    stats += fours * 1.0; 
    stats += sixes * 1.0; 
    
    // Milestones
    if (runs >= 50) stats += 8;
    if (runs >= 100) stats += 16;
    
    // Duck
    if (runs == 0 && isDuck) stats -= 2; 
    
    return stats;
  }

  static double calculateBowlingStats({
    required int wickets,
    required int maidens,
    int lbwOrBowled = 0,
  }) {
    double stats = 0;
    
    // Base Wickets
    stats += wickets * 25.0;
    
    // LBW/Bowled Bonus
    stats += lbwOrBowled * 8.0;
    
    // Wicket Haul Bonuses (Non-cumulative, highest tier only)
    if (wickets >= 5) {
      stats += 16;
    } else if (wickets >= 4) {
      stats += 8;
    } else if (wickets >= 3) {
      stats += 4;
    }

    // Maidens
    if (maidens > 0) {
      stats += maidens * 8.0; 
    }

    return stats;
  }

  static double calculateFieldingStats({
    required int catches,
    required int stumpings,
    required int runouts,
  }) {
    double stats = 0;
    stats += catches * 8.0;
    stats += stumpings * 12.0;
    stats += runouts * 6.0;
    return stats;
  }
}
