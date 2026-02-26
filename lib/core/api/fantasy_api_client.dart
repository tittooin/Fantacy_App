
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the API Client
final fantasyApiClientProvider = Provider<FantasyApiClient>((ref) {
  return FantasyApiClient();
});

class FantasyApiClient {
  late final Dio _dio;
  
  // Base URL for Cloudflare Worker
  static const String _baseUrl = 'https://fantasy-cricket-api.moremagical4.workers.dev';

  // Public Getter for Providers
  Dio get dio => _dio;

  FantasyApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    // Log Interceptor for Debugging (Optional)
    // _dio.interceptors.add(LogInterceptor(responseBody: true));
  }

  /// 1. Fetch Match List (Schedule + Live)
  Future<List<Map<String, dynamic>>> getMatches() async {
    try {
      final response = await _dio.get('/matches');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['matches'] ?? []);
      }
      return [];
    } catch (e) {
      // Graceful error handling - return empty list so UI doesn't crash
      // In production, we might log this to Crashlytics
      print('❌ Error fetching matches: $e');
      return [];
    }
  }

  /// 2. Fetch Live Scorecard
  Future<Map<String, dynamic>?> getScorecard(String matchId) async {
    try {
      final response = await _dio.get('/scorecard', queryParameters: {'id': matchId});
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['scorecard'];
      }
      return null;
    } catch (e) {
      print('❌ Error fetching scorecard for $matchId: $e');
      return null;
    }
  }

  /// 3. Fetch Fantasy Points
  Future<List<Map<String, dynamic>>> getFantasyPoints(String matchId) async {
    try {
      final response = await _dio.get('/fantasy-points', queryParameters: {'match_id': matchId});
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['points'] ?? []);
      }
      return [];
    } catch (e) {
      print('❌ Error fetching points for $matchId: $e');
      return [];
    }
  }

  /// 4. Fetch Squads (Optional Helper)
  Future<Map<String, dynamic>?> getSquads(String matchId) async {
    try {
       print("🚀 API Client: Fetching Squads for $matchId");
       final response = await _dio.get('/api/squads', queryParameters: {'matchId': matchId});
       
       print("📥 API Client: Response Status: ${response.statusCode}");
       
       if (response.statusCode == 200) {
          return response.data;
       }
       print("⚠️ API Client: API returned ${response.statusCode}");
       return null;
    } catch (e) {
       print("❌ API Client Error (getSquads): $e");
       return null;
    }
  }

  /// 5. Fetch Contests for a Match (D1)
  Future<List<Map<String, dynamic>>> getContests(String matchId) async {
    try {
      final response = await _dio.get('/api/contests', queryParameters: {'matchId': matchId});
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['contests'] ?? []);
      }
      return [];
    } catch (e) {
      print('❌ Error fetching contests for $matchId: $e');
      return [];
    }
  }

  /// 6. Create Contest (Admin Only - D1)
  Future<Map<String, dynamic>> createContest(Map<String, dynamic> contestData) async {
    try {
      final response = await _dio.post('/api/admin/contests/create', data: contestData);
      return response.data;
    } catch (e) {
      print('❌ Error creating contest: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 7. Join Contest (D1)
  Future<Map<String, dynamic>> joinContest(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post('/api/join-contest', data: payload);
      return response.data;
    } catch (e) {
      print('❌ Error joining contest: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  /// 7. Sync User to D1 (Auto-create if not exists)
  Future<Map<String, dynamic>> syncUser(String userId, String email, String displayName) async {
    try {
      final response = await _dio.post('/api/user/sync', data: {
        'userId': userId,
        'email': email,
        'displayName': displayName,
      });
      if (response.statusCode == 200) {
        return response.data;
      }
      return {'success': false, 'error': 'Failed to sync user'};
    } catch (e) {
      print('❌ Error syncing user: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  /// 8. Fetch User Joined Contests (D1)
  Future<List<Map<String, dynamic>>> getUserContests(String userId) async {
    try {
      final response = await _dio.get('/api/user/contests', queryParameters: {'userId': userId});
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['contests'] ?? []);
      }
      return [];
    } catch (e) {
      print('❌ Error fetching user contests for $userId: $e');
      return [];
    }
  }

  /// 9. Save/Create Team (D1)
  Future<Map<String, dynamic>> saveTeam(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post('/api/teams/save', data: payload);
      if (response.statusCode == 200) {
        return response.data;
      }
      return {'success': false, 'error': 'Failed to save team'};
    } catch (e) {
      print('❌ Error saving team: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 10. Fetch Room Leaderboard (D1)
  Future<List<Map<String, dynamic>>> getRoomLeaderboard(String matchId) async {
    try {
      final response = await _dio.get('/api/room/leaderboard', queryParameters: {'matchId': matchId});
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['leaderboard'] ?? []);
      }
      return [];
    } catch (e) {
      print('❌ Error fetching room leaderboard: $e');
      return [];
    }
  }
}
