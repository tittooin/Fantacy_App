
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
    required List<String> xiA, // List of Player IDs
    required List<String> xiB,
  }) async {
    try {
      debugPrint("🔍 FIRESTORE SAVE ATTEMPT STARTING..."); // VERIFICATION LOG
      // Save directly to Firestore instead of Worker API
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      await firestore.collection('matches').doc(matchId).set({
        'squad': {
          'teamA': teamA,
          'teamB': teamB,
          'xiA': xiA,
          'xiB': xiB,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));  // Merge to not overwrite other match data
      
      debugPrint("✅ Squad saved to Firestore successfully!");
    } catch (e) {
      debugPrint("AdminRepo: Save Squad Failed: $e");
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getSquad(String matchId) async {
    try {
      // Fetch from Firestore instead of Worker API
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('matches').doc(matchId).get();
      
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('squad')) {
          return {'success': true, ...data['squad']};
        }
      }
      return {'success': false};
    } catch (e) {
      debugPrint("AdminRepo: Get Squad Failed: $e");
      return {'success': false};
    }
  }

  Future<void> publishManualSquad(String matchId) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final matchDoc = await firestore.collection('matches').doc(matchId).get();
      
      if (!matchDoc.exists || matchDoc.data() == null) {
        throw Exception("Match not found");
      }
      
      final data = matchDoc.data()!;
      if (!data.containsKey('squad')) {
        throw Exception("No manual squad saved. Please save squad first.");
      }
      
      final squadData = data['squad'];
      final teamA = List<Map<String, dynamic>>.from(squadData['teamA'] ?? []);
      final teamB = List<Map<String, dynamic>>.from(squadData['teamB'] ?? []);
      final xiA = List<String>.from(squadData['xiA'] ?? []);
      final xiB = List<String>.from(squadData['xiB'] ?? []);
      
      // Combine all players
      final allPlayers = [...teamA, ...teamB];
      final playingXIIds = [...xiA, ...xiB]; // For verify
      
      if (allPlayers.isEmpty) {
        throw Exception("Squad is empty");
      }

      debugPrint("🚀 Publishing ${allPlayers.length} players to Subcollection...");
      
      final batch = firestore.batch();
      final playersRef = firestore.collection('matches').doc(matchId).collection('players');
      
      // 1. Delete old players (optional - better to overwrite)
      // For now we overwrite by ID
      
      for (var p in allPlayers) {
        final pid = p['id'].toString();
        // Ensure required fields
        p['matchId'] = int.tryParse(matchId) ?? 0;
        
        // Add to batch
        batch.set(playersRef.doc(pid), p);
      }
      
      // 2. Update Match Document with playingXI identifiers (if needed by app)
      // Usually user app checks subcollection, but keeping match-level metadata is good
      batch.set(firestore.collection('matches').doc(matchId), {
         'isSquadPublished': true,
         'playingXI': playingXIIds, // List of IDs
         'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      await batch.commit();
      debugPrint("✅ Manual Squad Published Successfully!");
      
    } catch (e) {
      debugPrint("AdminRepo: Publish Failed: $e");
      rethrow;
    }
  }
}
