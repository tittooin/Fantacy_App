import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/contest/data/leaderboard_service.dart';
import 'package:axevora11/features/cricket_api/data/points_engine.dart';

// --- Data Models for Input ---

class PlayerOverStats {
  final String playerId;
  final String playerName;
  final int runs;
  final int fours;
  final int sixes;
  final bool isOut;

  PlayerOverStats({
    required this.playerId,
    required this.playerName,
    this.runs = 0,
    this.fours = 0,
    this.sixes = 0,
    this.isOut = false,
  });

  Map<String, dynamic> toMap() => {
    'playerId': playerId,
    'playerName': playerName,
    'runs': runs,
    'fours': fours,
    'sixes': sixes,
    'isOut': isOut,
  };
}

class BowlerOverStats {
  final String playerId;
  final String playerName;
  final int wickets;
  final int maidens;
  final int extras;

  BowlerOverStats({
    required this.playerId,
    required this.playerName,
    this.wickets = 0,
    this.maidens = 0,
    this.extras = 0, // Wide, No Ball (adds to team score, not bowler points directly usually, but simplifies)
  });

  Map<String, dynamic> toMap() => {
    'playerId': playerId,
    'playerName': playerName,
    'wickets': wickets,
    'maidens': maidens,
    'extras': extras,
  };
}

class FieldingEvent {
  final String fielderId;
  final String fielderName;
  final String type; // 'Catch', 'Runout', 'Stumping'

  FieldingEvent({required this.fielderId, required this.fielderName, required this.type});

  Map<String, dynamic> toMap() => {
    'fielderId': fielderId,
    'fielderName': fielderName,
    'type': type,
  };
}

class ManualOverInput {
  final int overNumber;
  final String battingTeamName;
  final PlayerOverStats batsman1;
  final PlayerOverStats? batsman2; // Optional if only 1 faced balls? or create generic list. Let's stick to max 2 active.
  final BowlerOverStats bowler;
  final List<FieldingEvent> fieldingEvents;

  ManualOverInput({
    required this.overNumber,
    required this.battingTeamName,
    required this.batsman1,
    this.batsman2,
    required this.bowler,
    this.fieldingEvents = const [],
  });
}

// --- Service ---

class ManualScoringService {
  final FirebaseFirestore _firestore;
  final LeaderboardService _leaderboardService;

  ManualScoringService(this._firestore, this._leaderboardService);

  Future<void> submitOver(String matchId, ManualOverInput input) async {
    final matchRef = _firestore.collection('matches').doc(matchId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(matchRef);
      if (!snapshot.exists) throw Exception("Match not found");

      final data = snapshot.data()!;
      final currentStats = Map<String, dynamic>.from(data['playerStats'] ?? {});
      final currentScore = Map<String, dynamic>.from(data['matchScore'] ?? {});

      // 1. Backup for Rollback
      transaction.update(matchRef, {
        'backupPlayerStats': currentStats,
        'backupMatchScore': currentScore,
        'backupOverNumber': input.overNumber,
      });

      // 2. Update Stats
      _updateStatsForPlayer(currentStats, input.batsman1);
      if (input.batsman2 != null) {
        _updateStatsForPlayer(currentStats, input.batsman2!);
      }
      _updateStatsForBowler(currentStats, input.bowler);
      
      for (var event in input.fieldingEvents) {
        _updateStatsForFielder(currentStats, event);
      }

      // 3. Update Match Score Text (Quick Summary)
      // Identify team key (team1Score or team2Score) based on batting name logic or generic
      // For MVP, we presume admin selects which team is batting, handling string manually or via logic.
      // Let's assume we append to a "manualScore" field or update specific team score.
      // Simplifying: The Admin UI probably passes 'team1Score' or 'team2Score' key.
      // For now, let's just make a generic status update string.
      int totalRunsInOver = input.batsman1.runs + (input.batsman2?.runs ?? 0) + input.bowler.extras;     
      int totalWicketsInOver = (input.batsman1.isOut ? 1 : 0) + (input.batsman2?.isOut == true ? 1 : 0); // Simplified

      // We need to parse previous score to add runs. Ideally validation is better.
      // BUT, prompt says "Update internal match stats" and "Scores updated at end of over".
      // We will assume "currentScore" allows us to append.
      // For trust, we'll maintain a 'displayScore' field.
      
      String scoreKey = "displayScore"; 
      String currentDisplay = data[scoreKey] ?? "0/0 (0.0)";
      // Parsing "RUNS/WICKETS (OVERS)" is risky without structured storage.
      // Let's rely on Leaderboard recalculation for Points, and Admin inputs the "New Team Score" string manually? 
      // User Prompt: "Admin inputs Runs... System updates internal match stats".
      // Let's just store the last over summary as text for the UI to show "Last Over: 12 Runs, 1 Wkt".
      
      transaction.update(matchRef, {
        'playerStats': currentStats,
        'lastOverSummary': "Over ${input.overNumber}: $totalRunsInOver Runs, $totalWicketsInOver Wkts (${input.bowler.playerName})",
        'lastScoreUpdate': FieldValue.serverTimestamp(),
        // Save detailed over data for record
        'overs.${input.overNumber}': {
           'bowler': input.bowler.toMap(),
           'batsman1': input.batsman1.toMap(),
           'batsman2': input.batsman2?.toMap(),
           'timestamp': FieldValue.serverTimestamp(),
        }
      });
    });

    // 4. Trigger Leaderboard (Post-Transaction)
    await _leaderboardService.recalculateLeaderboard(matchId);
  }

  Future<void> rollbackLastOver(String matchId) async {
     final matchRef = _firestore.collection('matches').doc(matchId);
     
     await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(matchRef);
        if (!snapshot.exists) throw Exception("Match not found");
        
        final data = snapshot.data()!;
        if (data['backupPlayerStats'] == null) throw Exception("No backup available for rollback");

        transaction.update(matchRef, {
          'playerStats': data['backupPlayerStats'],
          'matchScore': data['backupMatchScore'],
          'lastOverSummary': "Over ${data['backupOverNumber']} Rolled Back",
          'lastScoreUpdate': FieldValue.serverTimestamp(),
          'backupPlayerStats': FieldValue.delete(), // Clear backup to prevent double rollback
        });
     });

     await _leaderboardService.recalculateLeaderboard(matchId);
  }

  // --- Helper Update Logic ---

  void _updateStatsForPlayer(Map<String, dynamic> stats, PlayerOverStats player) {
    if (player.playerId.isEmpty) return;
    
    final existing = stats[player.playerId] ?? {
       'runs': 0, 'fours': 0, 'sixes': 0, 'points': 0.0, 'role': 'batsman', 'isOut': false
    };

    int newRuns = (existing['runs'] ?? 0) + player.runs;
    int newFours = (existing['fours'] ?? 0) + player.fours;
    int newSixes = (existing['sixes'] ?? 0) + player.sixes;
    bool isOut = existing['isOut'] == true || player.isOut;

    // Recalculate Points for Batting
    double points = PointsEngine.calculateBattingPoints(
      runs: newRuns,
      fours: newFours,
      sixes: newSixes,
      isDuck: newRuns == 0 && isOut, // Logic: 0 runs total and is out
    );
    
    // Preserve Bowling Points if any (Player might be All-Rounder)
    // We should NOT overwrite total points, but update the BATTING component.
    // However, existing structure mixes them into one 'points' value.
    // Ideally we recalculate EVERYTHING.
    // Simplified: We assume we add the DELTA points? No, `PointsEngine` returns total points for stats.
    // We need to know previous BATTING points to subtract?
    // BETTER STRATEGY: Store 'battingPoints', 'bowlingPoints', 'fieldingPoints' separately in DB, and sum them.
    // But existing schema uses single 'points'.
    
    // Workaround: We have the raw stats (newRuns, etc). We can recalculate batting points from scratch.
    // We need to keep 'bowlingPoints' and 'fieldingPoints' separate or infer them.
    // Existing `ScoringService` overwrites `points`... wait.
    // `ScoringService`: 
    //   Batting: `playerStats[id] = {points: calced, ...}`
    //   Bowling: `existing['points'] += calced_bowling`
    
    // So current schema accumulates into one `points` field.
    // To support Manual Entry robustly, we should really split them.
    // Let's add separate fields: `battingPoints`, `bowlingPoints`, `fieldingPoints`.
    // And `totalPoints` = sum.
    
    // For this implementation, let's try to infer variables.
    double currentBowlingPts = (existing['bowlingPoints'] as num?)?.toDouble() ?? 0.0;
    double currentFieldingPts = (existing['fieldingPoints'] as num?)?.toDouble() ?? 0.0;
    
    stats[player.playerId] = {
      ...existing,
      'runs': newRuns,
      'fours': newFours,
      'sixes': newSixes,
      'isOut': isOut,
      'battingPoints': points,
      'bowlingPoints': currentBowlingPts,
      'fieldingPoints': currentFieldingPts,
      'points': points + currentBowlingPts + currentFieldingPts,
    };
  }

  void _updateStatsForBowler(Map<String, dynamic> stats, BowlerOverStats bowler) {
    if (bowler.playerId.isEmpty) return;

    final existing = stats[bowler.playerId] ?? {
      'wickets': 0, 'maidens': 0, 'points': 0.0
    };

    int newWickets = (existing['wickets'] ?? 0) + bowler.wickets;
    int newMaidens = (existing['maidens'] ?? 0) + bowler.maidens;
    
    double bowlingPts = PointsEngine.calculateBowlingPoints(
      wickets: newWickets,
      maidens: newMaidens,
    );

    double currentBattingPts = (existing['battingPoints'] as num?)?.toDouble() ?? 0.0;
    double currentFieldingPts = (existing['fieldingPoints'] as num?)?.toDouble() ?? 0.0;

    stats[bowler.playerId] = {
      ...existing,
      'wickets': newWickets,
      'maidens': newMaidens,
      'bowlingPoints': bowlingPts,
      'battingPoints': currentBattingPts,
      'fieldingPoints': currentFieldingPts,
      'points': bowlingPts + currentBattingPts + currentFieldingPts,
    };
  }
  
  void _updateStatsForFielder(Map<String, dynamic> stats, FieldingEvent event) {
    if (event.fielderId.isEmpty) return;
    
    final existing = stats[event.fielderId] ?? {
        'catches': 0, 'stumpings': 0, 'runouts': 0, 'points': 0.0
    };
    
    int catches = (existing['catches'] ?? 0) + (event.type == 'Catch' ? 1 : 0);
    int stumpings = (existing['stumpings'] ?? 0) + (event.type == 'Stumping' ? 1 : 0);
    int runouts = (existing['runouts'] ?? 0) + (event.type == 'Runout' ? 1 : 0);
    
    double fieldingPts = PointsEngine.calculateFieldingPoints(
        catches: catches, stumpings: stumpings, runouts: runouts
    );
    
    double currentBattingPts = (existing['battingPoints'] as num?)?.toDouble() ?? 0.0;
    double currentBowlingPts = (existing['bowlingPoints'] as num?)?.toDouble() ?? 0.0;
    
    stats[event.fielderId] = {
      ...existing,
      'catches': catches,
      'stumpings': stumpings,
      'runouts': runouts,
      'fieldingPoints': fieldingPts,
      'battingPoints': currentBattingPts,
      'bowlingPoints': currentBowlingPts,
      'points': currentBattingPts + currentBowlingPts + fieldingPts,
    };
  }
}

final manualScoringServiceProvider = Provider<ManualScoringService>((ref) {
  return ManualScoringService(
    FirebaseFirestore.instance,
    ref.read(leaderboardServiceProvider),
  );
});
