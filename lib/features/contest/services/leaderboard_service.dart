import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LeaderboardService {
  final Dio _dio = Dio();
  static const String _workerUrl = "https://fantasy-cricket-api.moremagical4.workers.dev";

  // Stream Leaderboard for UI (Auto-Update) - Hindi: Stream converted to periodic Future for D1
  Stream<List<Map<String, dynamic>>> getLeaderboardStream(String contestId) async* {
    while (true) {
      try {
        final response = await _dio.get('$_workerUrl/api/leaderboard?contestId=$contestId');
        if (response.statusCode == 200 && response.data['success'] == true) {
          yield List<Map<String, dynamic>>.from(response.data['leaderboard'] ?? []);
        }
      } catch (e) {
        debugPrint("LeaderboardService: Stream Fetch Error: $e");
      }
      await Future.delayed(const Duration(seconds: 30)); // 30s polling
    }
  }

  // Get My Rank - Hindi: D1 se specific user ki rank laata hai
  Future<Map<String, dynamic>?> getMyRank(String contestId, String userId) async {
    try {
      final response = await _dio.get('$_workerUrl/api/leaderboard?contestId=$contestId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final leaderboard = List<Map<String, dynamic>>.from(response.data['leaderboard'] ?? []);
        return leaderboard.firstWhere(
          (entry) => entry['user_id'] == userId,
          orElse: () => {},
        );
      }
    } catch (e) {
      debugPrint("LeaderboardService: Get Rank Error: $e");
    }
    return null;
  }
}
