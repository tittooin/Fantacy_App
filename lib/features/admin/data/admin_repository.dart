
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
      final url = "$_workerUrl/api/squads?matchId=$matchId";
      debugPrint("🔍 AdminRepo: Fetching Squad from $url");
      
      final response = await _dio.get(url);
      debugPrint("✅ AdminRepo: Response Code: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final data = response.data;
        // debugPrint("DATA: $data"); // Uncomment if needed

        List<dynamic> allPlayers = [];
        List<dynamic> teamA = [];
        List<dynamic> teamB = [];
        
        // 1. Handle List Response (Legacy)
        if (data is List) {
           debugPrint("ℹ️ Data is LIST of length ${data.length}");
           allPlayers = List.from(data);
        } 
        // 2. Handle Map Response
        else if (data is Map) {
           debugPrint("ℹ️ Data is MAP");
           if (data['teamA'] != null) {
              teamA = List.from(data['teamA']);
              debugPrint("Found teamA with ${teamA.length} players");
           }
           if (data['teamB'] != null) {
              teamB = List.from(data['teamB']);
              debugPrint("Found teamB with ${teamB.length} players");
           }
           
           if (data['players'] != null) {
             allPlayers = List.from(data['players']);
             debugPrint("Found 'players' list with ${allPlayers.length} items");
           }
        }

        // If explicitly separated, return as is
        if (teamA.isNotEmpty || teamB.isNotEmpty) {
           return {
             'success': true,
             'teamA': teamA,
             'teamB': teamB,
             'xiA': data['xiA'] ?? [],
             'xiB': data['xiB'] ?? [],
             'team1Id': data['team1Id'],
             'team2Id': data['team2Id'],
           };
        }

        if (allPlayers.isNotEmpty) {
           debugPrint("⚠️ Flattened List. Categorizing by teamShortName...");
           // Strategy: Group by teamShortName
            final groups = <String, List<dynamic>>{};
            for(var p in allPlayers) {
               final t = p['teamShortName'] ?? p['teamName'] ?? 'Unknown';
               if (!groups.containsKey(t)) groups[t] = [];
               groups[t]!.add(p);
            }
            
            debugPrint("⚠️ Found Groups: ${groups.keys}");

            if (groups.length >= 2) {
               final keys = groups.keys.toList();
               return {
                 'success': true,
                 'teamA': groups[keys[0]]!,
                 'teamB': groups[keys[1]]!,
                 'xiA': [],
                 'xiB': [],
               };
            } else {
               // Fallback: If only 1 group found, return it as Team A
               return {
                 'success': true,
                 'teamA': allPlayers,
                 'teamB': [],
                 'xiA': [],
                 'xiB': [],
               };
            }
        } else {
          debugPrint("❌ No players found in parsed data. Attempting Firestore Fallback...");
          
          // FALLBACK: Fetch from Firestore (Client SDK)
          // Since RapidApiService saves there, we should find it.
          try {
             final fs = FirebaseFirestore.instance;
             final snap = await fs.collection('matches').doc(matchId).collection('players').get();
             
             if (snap.docs.isNotEmpty) {
                debugPrint("✅ Firestore Fallback: Found ${snap.docs.length} players locally.");
                final fsPlayers = snap.docs.map((d) => d.data()).toList();
                
                // Reuse grouping logic
                final groups = <String, List<dynamic>>{};
                for(var p in fsPlayers) {
                   final t = p['teamShortName'] ?? p['teamName'] ?? 'Unknown';
                   if (!groups.containsKey(t)) groups[t] = [];
                   groups[t]!.add(p);
                }
                
                if (groups.length >= 2) {
                   final keys = groups.keys.toList();
                   return {
                     'success': true,
                     'teamA': groups[keys[0]]!,
                     'teamB': groups[keys[1]]!,
                     'xiA': [],
                     'xiB': [],
                   };
                } else {
                   return {
                     'success': true,
                     'teamA': fsPlayers,
                     'teamB': [],
                     'xiA': [],
                     'xiB': [],
                   };
                }
             } else {
                debugPrint("❌ Firestore Fallback: No players found there either.");
             }
          } catch (e) {
             debugPrint("❌ Firestore Fallback Error: $e");
          }
        }
      }
      return {'success': false, 'error': 'No Data/Empty'};
    } catch (e, stack) {
      debugPrint("❌ AdminRepo: Get Squad Failed: $e");
      debugPrint(stack.toString());
      return {'success': false, 'error': e.toString()};
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

      // 🚨 CRITICAL FIX: Force Assign Team IDs to players before saving
      // This ensures that even if Worker sends null, we overwrite it with the correct Match Team ID
      for (var p in teamA) {
        p['teamId'] = team1Id.toString();
      }
      for (var p in teamB) {
        p['teamId'] = team2Id.toString();
      }
      
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
