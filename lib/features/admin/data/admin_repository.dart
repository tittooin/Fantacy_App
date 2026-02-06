
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


final adminRepositoryProvider = Provider((ref) => AdminRepository());

class AdminRepository {
  final Dio _dio = Dio();
  static const String _workerUrl = "https://fantasy-cricket-api.moremagical4.workers.dev";
  // static const String _workerUrl = "http://localhost:8787"; // Debug

  Future<void> saveManualSquad({
    required String matchId,
    required List<Map<String, dynamic>> teamA,
    required List<Map<String, dynamic>> teamB,
    required List<String> xiA,
    required List<String> xiB,
  }) async {
    try {
      debugPrint("🔍 D1 SAVE ATTEMPT: Sending to Worker API...");
      
      final response = await _dio.post(
        "$_workerUrl/api/admin/match/squad",
        data: {
          'matchId': matchId,
          'teamA': teamA,
          'teamB': teamB,
          'xiA': xiA,
          'xiB': xiB,
        },
        options: Options(headers: {'Content-Type': 'application/json'})
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
         debugPrint("✅ Squad saved to D1 successfully!");
      } else {
         throw Exception(response.data['error'] ?? 'Unknown Error');
      }

    } catch (e) {
      debugPrint("AdminRepo: Save Squad Failed: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSquad(String matchId) async {
    try {
      // Fetch from Worker API (D1)
      final response = await _dio.get("$_workerUrl/api/squads?matchId=$matchId");
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'teamA': response.data['teamA'],
          'teamB': response.data['teamB'],
          'xiA': response.data['xiA'],
          'xiB': response.data['xiB'],
          'team1Id': response.data['team1Id'],
          'team2Id': response.data['team2Id'],
        };
      }
      return {'success': false};
    } catch (e) {
      debugPrint("AdminRepo: Get Squad Failed: $e");
      return {'success': false};
    }
  }

  Future<void> publishManualSquad(String matchId) async {
    try {
      debugPrint("🚀 Publishing Squad for Match: $matchId ...");
      
      // 1. Fetch Squad from D1 (using existing helper)
      final squadData = await getSquad(matchId);
      
      if (squadData['success'] != true) {
         throw Exception("No squad found on D1. Please Save Squad first.");
      }

      final teamA = List<Map<String, dynamic>>.from(squadData['teamA'] ?? []);
      final teamB = List<Map<String, dynamic>>.from(squadData['teamB'] ?? []);
      final xiA = List<String>.from(squadData['xiA'] ?? []);
      final xiB = List<String>.from(squadData['xiB'] ?? []);
      
      // Extract Team IDs from D1 response (Fix for Frontend Badge logic)
      final team1Id = squadData['team1Id'] ?? 0;
      final team2Id = squadData['team2Id'] ?? 0;
      
      // Combine all players
      final allPlayers = [...teamA, ...teamB];
      final playingXIIds = [...xiA, ...xiB]; // For verify
      
      if (allPlayers.isEmpty) {
        throw Exception("Squad is empty");
      }

      debugPrint("🚀 Syncing ${allPlayers.length} players to Firestore Subcollection (Legacy Support)...");
      
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      final playersRef = firestore.collection('matches').doc(matchId).collection('players');
      
      // 1. Sync Players to Subcollection
      for (var p in allPlayers) {
        final pid = p['id'].toString();
        // Ensure required fields
        p['matchId'] = int.tryParse(matchId) ?? 0;
        
        // Add to batch
        batch.set(playersRef.doc(pid), p);
      }
      
      // 2. Update Match Document with playingXI identifiers (Legacy + App Trigger)
      // Fix: Also write Team IDs so Frontend 'CreateTeamScreen' can map them
      batch.set(firestore.collection('matches').doc(matchId), {
         'isSquadPublished': true,
         'playingXI': playingXIIds, // List of IDs
         'team1Id': team1Id, // Vital for Badge Logic
         'team2Id': team2Id, // Vital for Badge Logic
         'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      await batch.commit();
      debugPrint("✅ Manual Squad Published & Synced Successfully!");
      
    } catch (e) {
      debugPrint("AdminRepo: Publish Failed: $e");
      rethrow;
    }
  }
}
