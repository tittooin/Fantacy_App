import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'package:axevora11/features/access/data/access_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccessCreditsNotifier extends StateNotifier<double> {
  final AccessRepository _repository;
  final Ref _ref;

  AccessCreditsNotifier(this._repository, this._ref) : super(0.0) {
    _init();
  }

  void _init() {
    // Listen to auth user changes to auto-fetch balance
    _ref.listen(authUserIdProvider, (previous, next) {
      if (next != null) {
        refresh();
      } else {
        state = 0.0;
      }
    });

    // Initial fetch if user is already logged in
    final userId = _ref.read(authUserIdProvider);
    if (userId != null) {
      refresh();
    }
  }

  Future<void> refresh() async {
    final userId = _ref.read(authUserIdProvider);
    if (userId == null) return;

    try {
      final balanceData = await _repository.getBalance(userId);
      state = (balanceData['total'] ?? 0.0).toDouble();
    } catch (e) {
      print("🚨 AccessCreditsNotifier: Fetch Failed: $e");
    }
  }
}

final accessCreditsProvider = StateNotifierProvider<AccessCreditsNotifier, double>((ref) {
  final repository = ref.watch(accessRepositoryProvider);
  return AccessCreditsNotifier(repository, ref);
});
