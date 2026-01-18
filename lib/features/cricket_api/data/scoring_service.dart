import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/contest/data/leaderboard_service.dart';
import 'package:axevora11/features/cricket_api/data/points_engine.dart';

class ScoringService {
  final FirebaseFirestore _firestore;
  final LeaderboardService _leaderboardService;

  ScoringService(this._firestore, this._leaderboardService);

  /// Main method to process a raw scorecard and update match stats
  Future<void> processScorecard(String matchId, Map<String, dynamic> scorecard) async {
    final playerStats = <String, Map<String, dynamic>>{};
    final matchScore = <String, dynamic>{};

    // [Parsing Logic - Same as before]
    if (scorecard.containsKey('scoreCard')) {
       final innings = scorecard['scoreCard'] as List<dynamic>;
       for (var i = 0; i < innings.length; i++) {
          final inning = innings[i];
          
          // Extract Team Score Summary (e.g. "145/3 (20)")
          // Structure depends on API. Assuming generic 'scoreDetails' or building from data.
          // For RapidAPI Cricbuzz, it's often in 'batTeamDetails' -> 'batTeamShortName' & 'runs'/'wickets'
          if (inning['batTeamDetails'] != null) {
             final batDetails = inning['batTeamDetails'];
             final teamName = batDetails['batTeamShortName'] ?? "Team ${i+1}";
             final runs = batDetails['runs'] ?? 0;
             final wickets = batDetails['wickets'] ?? 0;
             final overs = batDetails['overs'] ?? 0.0;
             
             matchScore['team${i+1}Score'] = "$teamName $runs/$wickets ($overs)";
          }

          // Process Batting
          if (inning['batTeamDetails'] != null && inning['batTeamDetails']['batsmenData'] != null) {
             final batsData = inning['batTeamDetails']['batsmenData'] as Map<String, dynamic>;
             batsData.forEach((key, value) {
                final playerId = value['batId']?.toString() ?? key; 
                final points = _calculateBattingPoints(value);
                
                playerStats[playerId] = {
                  'points': points,
                  'runs': value['runs'] ?? 0,
                  'fours': value['fours'] ?? 0,
                  'sixes': value['sixes'] ?? 0,
                  'role': 'batsman'
                };
             });
          }

          // Process Bowling
          if (inning['bowlTeamDetails'] != null && inning['bowlTeamDetails']['bowlersData'] != null) {
             final bowlsData = inning['bowlTeamDetails']['bowlersData'] as Map<String, dynamic>;
             bowlsData.forEach((key, value) {
                final playerId = value['bowlId']?.toString() ?? key;
                final points = _calculateBowlingPoints(value);
                
                final existing = playerStats[playerId] ?? {'points': 0.0};
                existing['points'] = (existing['points'] as double) + points;
                existing['wickets'] = value['wickets'] ?? 0;
                playerStats[playerId] = existing;
             });
          }
       }
    }

    // Save to Firestore & Trigger Leaderboard
    if (playerStats.isNotEmpty) { // Still check stats to ensure data validity
      await _firestore.collection('matches').doc(matchId).update({
        'playerStats': playerStats,
        'matchScore': matchScore, // New Field
        'lastScoreUpdate': FieldValue.serverTimestamp(),
      });
      
      await _leaderboardService.recalculateLeaderboard(matchId);
    }
  }

  // [Helper Calculations - Delegated to PointsEngine]
  double _calculateBattingPoints(Map<String, dynamic> data) {
    final runs = (data['runs'] as num?)?.toInt() ?? 0;
    final fours = (data['fours'] as num?)?.toInt() ?? 0;
    final sixes = (data['sixes'] as num?)?.toInt() ?? 0;
    final isOut = data['isOut'] == true;
    
    return PointsEngine.calculateBattingPoints(
      runs: runs,
      fours: fours,
      sixes: sixes,
      isDuck: runs == 0 && isOut,
    );
  }

  double _calculateBowlingPoints(Map<String, dynamic> data) {
    final wickets = (data['wickets'] as num?)?.toInt() ?? 0;
    final maidens = (data['maidens'] as num?)?.toInt() ?? 0;

    return PointsEngine.calculateBowlingPoints(
      wickets: wickets,
      maidens: maidens,
    );
  }
}

final scoringServiceProvider = Provider<ScoringService>((ref) {
  return ScoringService(FirebaseFirestore.instance, ref.read(leaderboardServiceProvider));
});
