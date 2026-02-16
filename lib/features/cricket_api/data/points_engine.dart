class PointsEngine {
  static double calculateBattingPoints({
    required int runs,
    required int fours,
    required int sixes,
    required bool isDuck,
  }) {
    double points = 0;
    
    // Base Runs
    points += runs * 1.0;
    
    // Boundaries
    points += fours * 1.0; 
    points += sixes * 1.0; 
    
    // Milestones
    if (runs >= 50) points += 8;
    if (runs >= 100) points += 16;
    
    // Duck
    if (runs == 0 && isDuck) points -= 2; 
    
    return points;
  }

  static double calculateBowlingPoints({
    required int wickets,
    required int maidens,
    int lbwOrBowled = 0,
  }) {
    double points = 0;
    
    // Base Wickets
    points += wickets * 25.0;
    
    // LBW/Bowled Bonus
    points += lbwOrBowled * 8.0;
    
    // Wicket Haul Bonuses (Non-cumulative, highest tier only)
    if (wickets >= 5) {
      points += 16;
    } else if (wickets >= 4) {
      points += 8;
    } else if (wickets >= 3) {
      points += 4;
    }

    // Maidens
    if (maidens > 0) {
      points += maidens * 8.0; 
    }

    return points;
  }

  static double calculateFieldingPoints({
    required int catches,
    required int stumpings,
    required int runouts,
  }) {
    double points = 0;
    points += catches * 8.0;
    points += stumpings * 12.0;
    points += runouts * 6.0;
    return points;
  }
}
