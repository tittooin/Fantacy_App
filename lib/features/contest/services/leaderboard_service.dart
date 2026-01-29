import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream Leaderboard for UI (Auto-Update)
  Stream<List<Map<String, dynamic>>> getLeaderboardStream(String contestId) {
    return _firestore
        .collection('contests')
        .doc(contestId)
        .collection('participants')
        .orderBy('points', descending: true) // Points desc
        .orderBy('teamName') // Tie-breaker
        .limit(100) // Top 100 for MVP
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }

  // Get My Rank
  Future<Map<String, dynamic>?> getMyRank(String contestId, String userId) async {
    // This requires good indexing or just reading specific doc if we know teamId.
    // If user has multiple teams, we show the best one?
    // For now, let's fetch all user teams in this contest
    final snapshot = await _firestore
        .collection('contests')
        .doc(contestId)
        .collection('participants')
        .where('userId', isEqualTo: userId)
        .orderBy('points', descending: true)
        .get();
        
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data();
    }
    return null;
  }
}
