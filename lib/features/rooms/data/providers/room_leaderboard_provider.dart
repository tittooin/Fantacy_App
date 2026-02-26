import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/fantasy_api_client.dart';
import 'dart:async';

final roomLeaderboardProvider = StateNotifierProvider.family<RoomLeaderboardNotifier, AsyncValue<List<Map<String, dynamic>>>, String>((ref, matchId) {
  final client = ref.watch(fantasyApiClientProvider);
  return RoomLeaderboardNotifier(client, matchId);
});

class RoomLeaderboardNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final FantasyApiClient _client;
  final String _matchId;
  Timer? _timer;

  RoomLeaderboardNotifier(this._client, this._matchId) : super(const AsyncValue.loading()) {
    fetch();
    _timer = Timer.periodic(const Duration(seconds: 45), (timer) => fetch());
  }

  Future<void> fetch() async {
    try {
      final data = await _client.getRoomLeaderboard(_matchId);
      if (mounted) state = AsyncValue.data(data);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
