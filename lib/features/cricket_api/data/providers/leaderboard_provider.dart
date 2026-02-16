import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/cricket_api/data/services/rapid_api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

final leaderboardProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, contestId) {
  // 📡 FETCH FROM D1 (Worker API) instead of Firestore
  // Hindi: Leaderboard ab D1/Worker se fetch hoga
  return ref.read(rapidApiServiceProvider).fetchLeaderboard(contestId);
});
