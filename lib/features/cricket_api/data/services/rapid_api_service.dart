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
        
        // LOG RAW RESPONSE FOR DEBUGGING
        if (kDebugMode) {
           debugPrint("🔍 Worker Raw Response: $data");
        }

        if (data['success'] == true) {
          debugPrint("✅ Worker → Success: ${data['message']}");
          // Fix: Return matches if available so Import Dialog can show them
          if (data['matches'] != null) {
            final List<dynamic> list = data['matches'];
            if (list.isEmpty) {
               debugPrint("⚠️ Worker returned EMPTY 'matches' list.");
            } else {
               debugPrint("✅ Worker → Returning ${list.length} matches for Import");
               if (list.isNotEmpty) {
                 debugPrint("🔍 FIRST MATCH RAW: ${list.first}");
               }
            }
            // Fix: Use fromMap because Worker sends FLATTENED data (processed), not Raw Nested JSON
            return list.map((m) {
              // debugPrint("Parsing match: $m"); 
              return CricketMatchModel.fromMap(m);
            }).toList();
          } else {
             debugPrint("⚠️ Worker Response Missing 'matches' key.");
          }
          return [];
        } else {
          debugPrint("⚠️ Worker → Error: ${data['error'] ?? data['message']}");
          if (data['tip'] != null) debugPrint("💡 Tip: ${data['tip']}");
        }
      } else {
         debugPrint("❌ Worker HTTP Error: ${response.statusCode}");
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
          return list.map((m) => CricketMatchModel.fromMap(m)).toList();
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
      debugPrint("📡 [Worker] GET /api/squads?matchId=$cricbuzzId&force=true");
      final response = await _dio.get(
        '$_workerUrl/api/squads?matchId=$cricbuzzId&force=true',
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> players = [];

        // Handle both List (Direct) and Map (Wrapper) responses
        if (data is List) {
          players = data;
        } else if (data is Map && data['success'] == true) {
             // Phase 2: Handle teamA and teamB split
             if (data['teamA'] != null || data['teamB'] != null) {
                  players = [
                      ...?(data['teamA'] as List?),
                      ...?(data['teamB'] as List?)
                  ];
             } 
             // Phase 1 Legacy: 'players' key
             else if (data['players'] != null) {
                  players = data['players'];
             }
        }

        if (players.isNotEmpty) {
          debugPrint("✅ Worker → Received ${players.length} players. Saving to Firestore...");
          debugPrint("🔍 DEBUG: First player data: ${players.first}");
          
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
               // DEBUG: Log what Worker returned for teamShortName
               debugPrint("🔍 Worker Data - Player: ${p['name']}, teamShortName: '${p['teamShortName']}'");
               
               final docRef = collectionRef.doc(p['id'].toString());
               batch.set(docRef, p);
             }
          }
          
          await batch.commit();
          debugPrint("✅ Firestore → Squad Saved!");
        } else {
           debugPrint("❌ Worker Response Data: $data"); // Log actual data
           throw Exception("Worker returned no players. Response: $data");
        }
      } else {
        throw Exception("Worker API Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Worker Squads Error: $e");
      rethrow;
    }
  }

  /// Endpoint 6: Manual Payout Trigger (Admin Only)
  Future<Map<String, dynamic>> distributePrizes(String matchId) async {
    try {
      debugPrint("📡 [Worker] POST /api/admin/payouts/distribute");
      final response = await _dio.post(
        '$_workerUrl/api/admin/payouts/distribute',
        data: {'matchId': matchId},
      );
      
      if (response.statusCode == 200) {
        debugPrint("✅ Payout Triggered: ${response.data}");
        return response.data;
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Payout Error: $e");
      return {'success': false, 'error': e.toString()};
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

  /// Endpoint 9: Join Contest (D1 Wallet Logic)
  Future<Map<String, dynamic>> joinContest(Map<String, dynamic> payload) async {
    try {
      debugPrint("📡 [Worker] POST /api/join-contest");
      final response = await _dio.post(
        '$_workerUrl/api/join-contest',
        data: payload,
      );
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {'success': false, 'error': "Server Error: ${response.statusCode}"};
      }
    } catch (e) {
      debugPrint("❌ Join Contest Error: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Endpoint 8: Admin Stats (D1 Aggregation)
  Future<Map<String, dynamic>> fetchAdminStats() async {
    try {
      final response = await _dio.get('$_workerUrl/api/admin/stats');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['stats'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("❌ Admin Stats Error: $e");
    }
    return {};
  }

  /// Endpoint 10: Participant Audit (Admin)
  Future<List<Map<String, dynamic>>> getParticipantsForMatch(String matchId) async {
    try {
      debugPrint("📡 [Worker] GET /api/admin/match/participants?matchId=$matchId");
      final response = await _dio.get('$_workerUrl/api/admin/match/participants?matchId=$matchId');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['participants']);
      }
    } catch (e) {
      debugPrint("❌ Audit Error: $e");
    }
    return [];
  }
  /// Endpoint 11: Sync User to D1
  Future<Map<String, dynamic>> syncUser(String userId, String email, String displayName) async {
    try {
      debugPrint("📡 [Worker] POST /api/user/sync");
      final response = await _dio.post('$_workerUrl/api/user/sync', data: {
        'userId': userId,
        'email': email,
        'displayName': displayName,
      });
      if (response.statusCode == 200) {
        return response.data;
      }
      return {'success': false, 'error': 'Failed to sync user'};
    } catch (e) {
      debugPrint("❌ User Sync Error: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Endpoint 12: Fetch Contests for a Match (D1)
  /// Hindi: D1 se kisi match ke saare contests laata hai
  Future<List<ContestModel>> fetchContestsForMatch(String matchId) async {
    try {
      debugPrint("📡 [Worker] GET /api/match/contests?matchId=$matchId");
      final response = await _dio.get('$_workerUrl/api/match/contests?matchId=$matchId');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> list = response.data['contests'] ?? [];
        debugPrint("✅ Worker → Received ${list.length} contests from D1");
        return list.map((c) => ContestModel.fromJson(c)).toList();
      }
    } catch (e) {
      debugPrint("❌ Fetch Contests Error: $e");
    }
    return [];
  }

  /// Endpoint 13: Fetch Leaderboard for a Contest (D1)
  /// Hindi: D1 se contest ki top rankings laata hai
  Future<List<Map<String, dynamic>>> fetchLeaderboard(String contestId) async {
    try {
      debugPrint("📡 [Worker] GET /api/leaderboard?contestId=$contestId");
      final response = await _dio.get('$_workerUrl/api/leaderboard?contestId=$contestId');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> list = response.data['leaderboard'] ?? [];
        return List<Map<String, dynamic>>.from(list);
      }
    } catch (e) {
      debugPrint("❌ Fetch Leaderboard Error: $e");
    }
    return [];
  }

  /// Endpoint 14: Fetch User Joined Contests (D1)
  /// Hindi: D1 se user ke saare joined contests laata hai
  Future<List<Map<String, dynamic>>> fetchUserJoinedContests(String userId) async {
    try {
      debugPrint("📡 [Worker] GET /api/user/contests?userId=$userId");
      final response = await _dio.get('$_workerUrl/api/user/contests?userId=$userId');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> list = response.data['contests'] ?? [];
        return List<Map<String, dynamic>>.from(list);
      }
    } catch (e) {
      debugPrint("❌ Fetch User Contests Error: $e");
    }
    return [];
  }

  /// Endpoint 15: Fetch Single Contest (D1)
  /// Hindi: D1 se ek specific contest ki details laata hai
  Future<Map<String, dynamic>?> fetchContestById(String contestId) async {
    try {
      debugPrint("📡 [Worker] GET /api/contest?contestId=$contestId");
      final response = await _dio.get('$_workerUrl/api/contest?contestId=$contestId');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['contest'];
      }
    } catch (e) {
      debugPrint("❌ Fetch Contest Error: $e");
    }
    return null;
  }
}

/// Provider: RapidApiService ka instance
/// Hindi: Riverpod provider jo service ko provide karta hai
final rapidApiServiceProvider = Provider<RapidApiService>((ref) {
  return RapidApiService(Dio());
});
