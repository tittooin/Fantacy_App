
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import '../../domain/cricket_contest_model.dart';
import 'package:flutter/foundation.dart';

final rapidApiServiceProvider = Provider((ref) => RapidApiService());

class RapidApiService {
  final _dio = Dio();
  final String _workerUrl = 'https://fantasy-cricket-api.moremagical4.workers.dev';

  /// Endpoint 3: Matches fetch karna (D1)
  Future<List<CricketMatchModel>> fetchMatches() async {
    try {
      final response = await _dio.get('$_workerUrl/api/matches');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['matches'] != null) {
          final List<dynamic> list = data['matches'];
          return list.map((m) => CricketMatchModel.fromMap(m)).toList();
        }
      }
    } catch (e) {
      debugPrint("❌ Worker Matches Error: $e");
    }
    return [];
  }

  Future<List<CricketMatchModel>> fetchLive() async => fetchMatches();
  Future<List<CricketMatchModel>> fetchFixtures() async => fetchMatches();
  Future<List<CricketMatchModel>> fetchLiveMatches() async => fetchMatches();

  /// Endpoint 4: Scorecard fetch karna
  Future<Map<String, dynamic>> fetchScorecard(String matchId) async {
    try {
      final response = await _dio.get('$_workerUrl/api/scorecard/$matchId');
      if (response.statusCode == 200) {
        return response.data['scorecard'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("❌ Worker Scorecard Error: $e");
    }
    return {};
  }

  /// Endpoint 5: Squads fetch (D1 only, no Firestore write)
  Future<Map<String, dynamic>> fetchSquads(String cricbuzzId) async {
    try {
      debugPrint("📡 [Worker] GET /api/squads?matchId=$cricbuzzId");
      final response = await _dio.get('$_workerUrl/api/squads?matchId=$cricbuzzId');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("❌ Worker Squads Error: $e");
    }
    return {};
  }

  /// Alias for fetchSquads for backward compatibility in Admin screens
  Future<Map<String, dynamic>> fetchAndSaveSquad(String matchId, String cricbuzzId) async {
    return fetchSquads(cricbuzzId);
  }

  /// Endpoint 6: Distribute Prizes (Admin only)
  Future<Map<String, dynamic>> distributePrizes(String matchId) async {
    try {
      final response = await _dio.post(
        '$_workerUrl/api/admin/payouts/distribute',
        data: {'matchId': matchId},
      );
      return response.data;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Endpoint 7: Join Contest (D1 Wallet Logic)
  Future<Map<String, dynamic>> joinContest(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post('$_workerUrl/api/join-contest', data: payload);
      return response.data;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Endpoint 8: Save Team (D1)
  Future<Map<String, dynamic>> saveTeam(Map<String, dynamic> payload) async {
    try {
      debugPrint("📡 [Worker] POST /api/teams/save");
      final response = await _dio.post('$_workerUrl/api/teams/save', data: payload);
      return response.data;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Endpoint 9: Fetch Teams (D1)
  Future<List<Map<String, dynamic>>> fetchTeams(String userId, {String? matchId}) async {
    try {
      String url = '$_workerUrl/api/teams/get?userId=$userId';
      if (matchId != null) url += '&matchId=$matchId';
      
      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['teams'] ?? []);
      }
    } catch (e) {
      debugPrint("❌ Fetch Teams Error: $e");
    }
    return [];
  }

  /// Endpoint 10: Sync User to D1
  Future<Map<String, dynamic>> syncUser(String userId, String email, String displayName) async {
    try {
      final response = await _dio.post('$_workerUrl/api/user/sync', data: {
        'userId': userId,
        'email': email,
        'displayName': displayName,
      });
      return response.data;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Endpoint 11: Participant Audit (Admin)
  Future<List<Map<String, dynamic>>> getParticipantsForMatch(String matchId) async {
    try {
      final response = await _dio.get('$_workerUrl/api/admin/match/participants?matchId=$matchId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['participants']);
      }
    } catch (e) {
      debugPrint("❌ Audit Error: $e");
    }
    return [];
  }

  /// Endpoint 12: Fetch Joined Contests (D1)
  Future<List<Map<String, dynamic>>> fetchUserJoinedContests(String userId) async {
    try {
      final response = await _dio.get('$_workerUrl/api/user/contests?userId=$userId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['contests'] ?? []);
      }
    } catch (e) {
      debugPrint("❌ Fetch User Contests Error: $e");
    }
    return [];
  }

  /// Endpoint 13: Fetch Contests for Match (D1)
  Future<List<CricketRoomModel>> fetchContestsForMatch(String matchId) async {
    try {
      final response = await _dio.get('$_workerUrl/api/rooms?matchId=$matchId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> list = response.data['contests'] ?? [];
        return list.map((c) => CricketRoomModel.fromJson(c)).toList();
      }
    } catch (e) {
      debugPrint("❌ Fetch Contests Error: $e");
    }
    return [];
  }

  /// Endpoint 14: Fetch Leaderboard (D1)
  Future<List<Map<String, dynamic>>> fetchLeaderboard(String contestId) async {
    try {
      final response = await _dio.get('$_workerUrl/api/leaderboard/$contestId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['leaderboard'] ?? []);
      }
    } catch (e) {
      debugPrint("❌ Fetch Leaderboard Error: $e");
    }
    return [];
  }

  /// Endpoint 15: Fetch Contest by ID (D1)
  Future<CricketRoomModel?> fetchContestById(String contestId) async {
    try {
      final response = await _dio.get('$_workerUrl/api/contest/$contestId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return CricketRoomModel.fromJson(response.data['contest']);
      }
    } catch (e) {
      debugPrint("❌ Fetch Contest By ID Error: $e");
    }
    return null;
  }

  /// Endpoint 16: Fetch Admin Stats (D1)
  Future<Map<String, dynamic>> fetchAdminStats() async {
    try {
      final response = await _dio.get('$_workerUrl/api/admin/stats');
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      debugPrint("❌ Fetch Admin Stats Error: $e");
    }
    return {'success': false, 'error': 'Failed to fetch stats'};
  }
}
