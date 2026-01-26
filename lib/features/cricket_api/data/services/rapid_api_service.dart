import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as import_firestore;

/// Cloudflare Worker Service - CORS issue solve karne ke liye
/// Hindi: Browser se direct RapidAPI call nahi hoti (CORS block)
/// Isliye Cloudflare Worker use kar rahe hain jo server-side se RapidAPI call karta hai
class RapidApiService {
  final Dio _dio;
  
  // Cloudflare Worker URL - ye server-side se RapidAPI call karega
  static const String _workerUrl = 'https://fantasy-cricket-api.moremagical4.workers.dev';

  RapidApiService(this._dio);

  /// Endpoint 1: Fixtures fetch karna (via Cloudflare Worker)
  /// Hindi: Worker se matches fetch karta hai jo RapidAPI se data laata hai
  Future<List<CricketMatchModel>> fetchFixtures() async {
    try {
      debugPrint("📡 [Worker] GET /api/refresh-matches");
      final response = await _dio.get('$_workerUrl/api/refresh-matches');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          debugPrint("✅ Worker → Success: ${data['message']}");
          return []; // UI will listen to Firestore
        } else {
          debugPrint("⚠️ Worker → Error: ${data['error'] ?? data['message']}");
          if (data['tip'] != null) debugPrint("💡 Tip: ${data['tip']}");
        }
      }
    } catch (e) {
      debugPrint("❌ Worker Fixture Error: $e");
    }
    return [];
  }

  /// Endpoint 2: All matches fetch karna
  /// Hindi: Worker se saved matches fetch karta hai
  Future<List<CricketMatchModel>> fetchMatches() async {
    try {
      debugPrint("📡 [Worker] GET /api/get-matches");
      final response = await _dio.get('$_workerUrl/api/get-matches');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['matches'] != null) {
          final List<dynamic> list = data['matches'];
          debugPrint("✅ Worker → Received ${list.length} matches from Firestore");
          return list.map((m) => CricketMatchModel.fromJson(m)).toList();
        }
      }
    } catch (e) {
      debugPrint("❌ Worker Matches Error: $e");
    }
    return [];
  }

  /// Endpoint 3: Live matches fetch karna
  /// Hindi: Same as fetchMatches for now
  Future<List<CricketMatchModel>> fetchLive() async {
    return fetchMatches();
  }

  /// Backward compatibility: fetchLiveMatches
  /// Hindi: Purane code ke liye
  Future<List<CricketMatchModel>> fetchLiveMatches() async {
    return fetchLive();
  }

  /// Endpoint 4: Scorecard fetch karna
  /// Hindi: Worker se scorecard fetch karta hai
  Future<Map<String, dynamic>> fetchScorecard(String matchId) async {
    try {
      debugPrint("📡 [Worker] GET /api/scorecard/$matchId");
      final response = await _dio.get(
        '$_workerUrl/api/scorecard/$matchId',
      );
      
      if (response.statusCode == 200) {
        debugPrint("✅ Worker → 200 OK (Scorecard)");
        return response.data['scorecard'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("❌ Worker Scorecard Error: $e");
    }
    return {};
  }

  /// Endpoint 5: Squads fetch and Save
  /// Hindi: Worker se squad laata hai aur Firestore mein save karta hai
  Future<void> fetchAndSaveSquad(String matchId, String cricbuzzId) async {
    try {
      debugPrint("📡 [Worker] GET /api/squads?matchId=$cricbuzzId");
      final response = await _dio.get(
        '$_workerUrl/api/squads?matchId=$cricbuzzId',
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> players = [];

        // Handle both List (Direct) and Map (Wrapper) responses
        if (data is List) {
          players = data;
        } else if (data is Map && data['success'] == true && data['players'] != null) {
          players = data['players'];
        }

        if (players.isNotEmpty) {
          debugPrint("✅ Worker → Received ${players.length} players. Saving to Firestore...");
          
          final batch = import_firestore.FirebaseFirestore.instance.batch();
          final collectionRef = import_firestore.FirebaseFirestore.instance
              .collection('matches')
              .doc(matchId)
              .collection('players');

          // Delete old players first (optional, but good for clean sync)
          // For now, we overwrite. 
          
          for (var p in players) {
             // Ensure 'id' exists
             if (p['id'] != null) {
               final docRef = collectionRef.doc(p['id'].toString());
               batch.set(docRef, p);
             }
          }
          
          await batch.commit();
          debugPrint("✅ Firestore → Squad Saved!");
        } else {
           throw Exception("Worker returned no players or invalid format");
        }
      }
    } catch (e) {
      debugPrint("❌ Worker Squads Error: $e");
      rethrow;
    }
  }

  /// Endpoint 5b: Squads fetch only (Raw)
  Future<Map<String, dynamic>> fetchSquads(int matchId) async {
    try {
      debugPrint("📡 [Worker] GET /api/squads?matchId=$matchId");
      final response = await _dio.get(
        '$_workerUrl/api/squads?matchId=$matchId',
      );
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("❌ Worker Squads Error: $e");
    }
    return {};
  }
  /// Hindi: Placeholder - will implement later
  Future<List<Map<String, dynamic>>> fetchPlayers(String teamId) async {
    debugPrint("⚠️ [Worker] fetchPlayers not implemented yet");
    return [];
  }

  /// Endpoint 7: Series fetch karna
  /// Hindi: Placeholder - will implement later
  Future<List<Map<String, dynamic>>> fetchSeries() async {
    debugPrint("⚠️ [Worker] fetchSeries not implemented yet");
    return [];
  }
}

/// Provider: RapidApiService ka instance
/// Hindi: Riverpod provider jo service ko provide karta hai
final rapidApiServiceProvider = Provider<RapidApiService>((ref) {
  return RapidApiService(Dio());
});
