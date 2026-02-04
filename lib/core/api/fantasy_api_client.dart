
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
       final response = await _dio.get('/squads', queryParameters: {'matchId': matchId});
       // D1 worker might implement this later, or we fallback to existing logic if needed
       // Assuming Worker has /squads or similar endpoint wrapper
       if (response.statusCode == 200) {
          return response.data;
       }
       return null;
    } catch (e) {
       return null;
    }
  }
}
