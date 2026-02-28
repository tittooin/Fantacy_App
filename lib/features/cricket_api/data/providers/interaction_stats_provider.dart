
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/axevora_api_client.dart';

// Key: Player ID, Value: Points
final interactionStatsProvider = StateNotifierProvider.family<InteractionStatsNotifier, AsyncValue<Map<String, double>>, String>((ref, matchId) {
  final client = ref.watch(axevoraApiClientProvider);
  return InteractionStatsNotifier(client, matchId);
});

class InteractionStatsNotifier extends StateNotifier<AsyncValue<Map<String, double>>> {
  final AxevoraApiClient _client;
  final String _matchId;
  Timer? _timer;

  InteractionStatsNotifier(this._client, this._matchId) : super(const AsyncValue.loading()) {
    fetchPoints();
    _startPolling();
  }

  Future<void> fetchPoints() async {
    try {
      final rawList = await _client.getInteractionStats(_matchId);
      
      // Convert List to Map<PlayerId, Points> for O(1) lookup
      final Map<String, double> pointsMap = {};
      
      for (var item in rawList) {
        final pid = item['player_id'].toString();
        final pts = (item['total_points'] ?? 0).toDouble();
        pointsMap[pid] = pts;
      }

      if (mounted) {
        state = AsyncValue.data(pointsMap);
      }
    } catch (e, stack) {
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  void _startPolling() {
    // Polling Rule: 60s
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      fetchPoints();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
