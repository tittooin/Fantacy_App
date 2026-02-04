import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

final leaderboardProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, contestId) {
  return FirebaseFirestore.instance
      .collection('contests')
      .doc(contestId)
      .collection('entries')
      .orderBy('points', descending: true)
      .limit(50) // Optimization: Read only top 50
      .snapshots()
      .map((snapshot) {
        debugPrint("🏆 Leaderboard Provider: Querying for contestId=$contestId");
        debugPrint("🏆 Found ${snapshot.docs.length} entries");
        if (snapshot.docs.isEmpty) {
           debugPrint("⚠️ No entries found! Check Firestore path: contests/$contestId/entries");
        }
        return snapshot.docs.map((doc) => doc.data()).toList();
      });
});
