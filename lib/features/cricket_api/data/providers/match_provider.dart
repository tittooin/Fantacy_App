
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/fantasy_api_client.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:cloud_firestore/cloud_firestore.dart'; // Added Import

/// Provider for the list of matches
final matchListProvider = StateNotifierProvider<MatchListNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final client = ref.watch(fantasyApiClientProvider);
  return MatchListNotifier(client);
});

class MatchListNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final FantasyApiClient _client;
  Timer? _timer;

  MatchListNotifier(this._client) : super(const AsyncValue.loading()) {
    fetchMatches();
    _startPolling();
  }

  Future<void> fetchMatches() async {
    try {
      // Don't set loading state on refresh to avoid UI flicker
      if (state.value == null) {
        state = const AsyncValue.loading();
      }
      
      final workerMatches = await _client.getMatches();

      // Normalize Worker Matches (Handle snake_case from D1)
      final normalizedMatches = workerMatches.map((m) {
        return {
          ...m,
          'seriesName': m['seriesName'] ?? m['series_name'] ?? m['title'] ?? '',
          'matchDesc': m['matchDesc'] ?? m['title'] ?? '', 
          'startDate': m['startDate'] ?? m['start_time'] ?? 0,
          'status': m['status'] ?? 'Upcoming',
        };
      }).toList();
      
      // Also fetch from Firestore (for Manual Matches created in Admin)
      final firestoreMatches = await _fetchFirestoreMatches();
      
      // Merge unique matches (prefer Worker if duplicate IDs exist, though unlikely)
      final Map<String, Map<String, dynamic>> mergedMap = {};
      
      for (var m in normalizedMatches) {
        if (m['id'] != null) mergedMap[m['id'].toString()] = m;
      }
      
      for (var m in firestoreMatches) {
        if (m['id'] != null) {
           // Only add if not already present (Worker takes precedence for automated matches)
           if (!mergedMap.containsKey(m['id'].toString())) {
             mergedMap[m['id'].toString()] = m;
           }
        }
      }
      
      final allMatches = mergedMap.values.toList();
      debugPrint("📊 MatchProvider: Total Matches after Merge: ${allMatches.length}");
      
      // Sort by start time (Ascending: Soonest First) for consistent UI
      // allMatches.sort((a, b) => (a['start_time'] ?? 0).compareTo(b['start_time'] ?? 0));
      
      if (mounted) {
        state = AsyncValue.data(allMatches);
      }
    } catch (e, stack) {
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }
  
  Future<List<Map<String, dynamic>>> _fetchFirestoreMatches() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      // Fetch Upcoming manual matches from Firestore
      final qs = await FirebaseFirestore.instance.collection('matches')
          .where('startDate', isGreaterThan: now) // Only future matches
          .limit(20)
          .get();
          
      return qs.docs.map((d) {
         final data = d.data();
         // Ensure crucial fields map to what UI/Worker expects
         return {
           'id': d.id, 
           'match_id': int.tryParse(d.id) ?? 0,
           'title': data['category'] ?? 'Active Match', 
           'seriesName': data['seriesName'] ?? data['title'] ?? '', // CRITICAL FIX
           'matchDesc': data['matchDesc'] ?? '',                   // CRITICAL FIX
           'team_a': data['team1ShortName'] ?? 'T1',   
           'team_b': data['team2ShortName'] ?? 'T2',   
           'team_a_img': data['team1Img'] ?? data['team1Logo'] ?? '', // Fix for Img key mismatch
           'team_b_img': data['team2Img'] ?? data['team2Logo'] ?? '', // Fix for Img key mismatch
           'start_time': data['startDate'] ?? 0,
           'startDate': data['startDate'] ?? 0, // Pass original key too
           'status': data['status'] ?? 'Upcoming',
           // Add flag to identify source
           'source': 'manual'
         };
      }).toList();
    } catch (e) {
      // debugPrint("Firestore Fetch Error: $e");
      return [];
    }
  }

  void _startPolling() {
    // Polling Rule: Minimum 60s
    _timer = Timer.periodic(const Duration(minutes: 2), (timer) {
      fetchMatches();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
