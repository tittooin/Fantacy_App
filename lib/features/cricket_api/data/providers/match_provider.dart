
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/fantasy_api_client.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

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
      final workerMatches = await _client.getMatches();

      // Normalize Worker Matches (Handle snake_case from D1)
      final allMatches = workerMatches.map((m) {
        return {
          ...m,
          'id': m['id']?.toString() ?? '',
          'seriesName': m['seriesName'] ?? m['series_name'] ?? m['title'] ?? '',
          'matchDesc': m['matchDesc'] ?? m['title'] ?? '', 
          'startDate': m['startDate'] ?? m['start_time'] ?? 0,
          'status': m['status'] ?? 'Upcoming',
        };
      }).toList();
      
      debugPrint("📊 MatchProvider: Total Matches from D1: ${allMatches.length}");
      
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
