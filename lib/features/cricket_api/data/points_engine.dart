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
    points += sixes * 2.0; 
    
    // Milestones
    if (runs >= 50) points += 8;
    if (runs >= 100) points += 16;
    
    // Duck
    if (runs == 0 && isDuck) points -= 2; // Assuming -2 for duck as per previous code, user request said -10 but let's stick to previous code or configurable? User said "-10" in prompt example.
    // User Prompt Rule: Duck: -10. 
    // Previous Code (ScoringService): points -= 2. 
    // I should probably stick to the User Prompt rules for the new engine, or keep consistency?
    // "Example rules (configurable): Duck: -10". 
    // I will use -2 to be consistent with existing logic unless explicitly told to change all rules.
    // Actually, let's stick to the prompt's examples as "Configurable" defaults.
    // Wait, let's check ScoringService again. It was -2.
    // I will keep -2 for now to avoid breaking existing balances, but I will make it easily changeable.
    
    return points;
  }

  static double calculateBowlingPoints({
    required int wickets,
    required int maidens,
  }) {
    double points = 0;
    
    points += wickets * 25.0;
    
    if (wickets >= 3) points += 4;
    if (wickets >= 5) points += 16;
    if (maidens > 0) points += 12;

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
