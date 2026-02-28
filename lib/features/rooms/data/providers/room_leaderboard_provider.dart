import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/axevora_api_client.dart';
import 'dart:async';

final roomLeaderboardProvider = StateNotifierProvider.family<RoomLeaderboardNotifier, AsyncValue<List<Map<String, dynamic>>>, Map<String, String>>((ref, params) {
  final client = ref.watch(axevoraApiClientProvider);
  return RoomLeaderboardNotifier(client, params['matchId'] ?? '', params['roomId']);
});

class RoomLeaderboardNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final AxevoraApiClient _client;
  final String _matchId;
  final String? _roomId;
  Timer? _timer;

  RoomLeaderboardNotifier(this._client, this._matchId, this._roomId) : super(const AsyncValue.loading()) {
    fetch();
    _timer = Timer.periodic(const Duration(seconds: 45), (timer) => fetch());
  }

  Future<void> fetch() async {
    try {
      final data = await _client.getRoomLeaderboard(_matchId, _roomId);
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
