
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/fantasy_api_client.dart';

// Family provider to fetch scorecard for specific matchID
final scorecardProvider = StateNotifierProvider.family<ScorecardNotifier, AsyncValue<Map<String, dynamic>?>, String>((ref, matchId) {
  final client = ref.watch(fantasyApiClientProvider);
  return ScorecardNotifier(client, matchId);
});

class ScorecardNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final FantasyApiClient _client;
  final String _matchId;
  Timer? _timer;

  ScorecardNotifier(this._client, this._matchId) : super(const AsyncValue.loading()) {
    fetchScorecard();
    _startPolling();
  }

  Future<void> fetchScorecard() async {
    try {
      final data = await _client.getScorecard(_matchId);
      if (mounted) {
        state = AsyncValue.data(data);
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
      fetchScorecard();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
