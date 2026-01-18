import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/team/domain/team_entity.dart';
// Note: We need access to Team Repository or fetch teams manually. 
// For efficiency in this service, we will fetch directly.

class LeaderboardService {
  final FirebaseFirestore _firestore;

  LeaderboardService(this._firestore);

  Future<void> recalculateLeaderboard(String matchId) async {
    // 1. Fetch Match Data (Player Stats)
    final matchDoc = await _firestore.collection('matches').doc(matchId).get();
    if (!matchDoc.exists || matchDoc.data() == null) return;
    
    final playerStats = matchDoc.data()!['playerStats'] as Map<String, dynamic>? ?? {};
    final playingXI = (matchDoc.data()!['playingXI'] as List<dynamic>?)?.map((e) => e.toString()).toSet();
    
    // 2. Fetch all Contests for this Match
    final contestsSnap = await _firestore.collection('matches').doc(matchId).collection('contests').get();

    for (var contestDoc in contestsSnap.docs) {
       await _processContest(matchId, contestDoc.id, playerStats, playingXI);
    }
  }

  Future<void> _processContest(String matchId, String contestId, Map<String, dynamic> playerStats, Set<String>? playingXI) async {
    final contestRef = _firestore.collection('matches').doc(matchId).collection('contests').doc(contestId);
    final entriesRef = contestRef.collection('entries');
    
    final entriesSnap = await entriesRef.get();
    
    List<Map<String, dynamic>> rankedEntries = [];

    // Batch for writes
    // Note: Firestore batch limit is 500. For production, chunks needed. MVP: Single batch usually ok.
    var batch = _firestore.batch();
    int batchCount = 0;

    for (var entryDoc in entriesSnap.docs) {
       final entryData = entryDoc.data();
       final teamId = entryData['teamId'];
       final userId = entryData['userId'];
       
       // Need to fetch output Team to get its players.
       // We can optimize this by storing 'playerIds' in the entry doc itself during join.
       // BUT, for now let's fetch the Team Doc.
       final teamDoc = await _firestore.collection('users').doc(userId).collection('teams').doc(teamId).get();
       
       if (!teamDoc.exists) continue;
       
       // Calculate Points
       final tData = teamDoc.data()!;
       // Manual Parsing from Map instead of Entity for speed
       final players = (tData['players'] as List).map((e) => e as Map<String, dynamic>).toList();
       final captainId = tData['captainId'];
       final vcId = tData['viceCaptainId'];

       double totalPoints = 0.0;

       for (var p in players) {
          final pid = p['id'].toString(); // Ensure String ID
          final pStat = playerStats[pid];
          
          if (pStat != null) {
            // Check Playing XI rule
            if (playingXI != null && playingXI.isNotEmpty) {
               if (!playingXI.contains(pid)) {
                 continue; // Skip points if not in Playing XI
               }
            }

            double pts = (pStat['points'] as num).toDouble();
            
            // Apply Multipliers
            if (pid == captainId) pts *= 2;
            else if (pid == vcId) pts *= 1.5;
            
            totalPoints += pts;
          }
       }
       
       rankedEntries.add({
         'docId': entryDoc.id,
         'points': totalPoints,
         ...entryData
       });
    }

    // Sort by Points Descending
    rankedEntries.sort((a, b) => (b['points'] as double).compareTo(a['points'] as double));

    // Update Ranks & Points
    for (int i = 0; i < rankedEntries.length; i++) {
       final entry = rankedEntries[i];
       final newRank = i + 1;
       final newPoints = entry['points'];
       
       final ref = entriesRef.doc(entry['docId']);
       batch.update(ref, {
         'points': newPoints,
         'rank': newRank,
       });
       batchCount++;

       if (batchCount >= 490) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
       }
    }
    
    if (batchCount > 0) await batch.commit();
  }
}

final leaderboardServiceProvider = Provider<LeaderboardService>((ref) {
  return LeaderboardService(FirebaseFirestore.instance);
});
