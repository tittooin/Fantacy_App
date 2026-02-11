import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'package:axevora11/features/wallet/data/wallet_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalletBalanceNotifier extends StateNotifier<double> {
  final WalletRepository _repository;
  final Ref _ref;

  WalletBalanceNotifier(this._repository, this._ref) : super(0.0) {
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
      print("🚨 WalletBalanceNotifier: Fetch Failed: $e");
    }
  }
}

final walletBalanceProvider = StateNotifierProvider<WalletBalanceNotifier, double>((ref) {
  final repository = ref.watch(walletRepositoryProvider);
  return WalletBalanceNotifier(repository, ref);
});
