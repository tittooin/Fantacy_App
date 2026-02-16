import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:axevora11/features/contest/domain/user_contest_entity.dart';
import 'package:axevora11/features/cricket_api/data/services/rapid_api_service.dart';
import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'package:axevora11/features/wallet/presentation/providers/wallet_provider.dart';

class UserContestNotifier extends Notifier<List<UserContestEntity>> {
  @override
  List<UserContestEntity> build() {
    final uid = ref.watch(authUserIdProvider);
    if (uid != null) {
      _fetchJoinedContests();
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser != null) _proactiveSyncUser(authUser);
    }
    return [];
  }

  void _proactiveSyncUser(User user) async {
    try {
      final apiService = ref.read(rapidApiServiceProvider);
      await apiService.syncUser(
        user.uid, 
        user.email ?? '', 
        user.displayName ?? 'User'
      );
    } catch (e) {
      debugPrint('⚠️ Proactive sync skipped/failed: $e');
    }
  }

  Future<void> _fetchJoinedContests() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final apiService = ref.read(rapidApiServiceProvider);
      final list = await apiService.fetchUserJoinedContests(user.uid);

      final contests = list.map((json) {
         return UserContestEntity(
            id: json['id']?.toString() ?? '',
            userId: json['user_id']?.toString() ?? user.uid,
            contestId: json['contest_id']?.toString() ?? '',
            matchId: json['match_id']?.toString() ?? '',
            teamId: json['team_id']?.toString() ?? '',
            teamName: json['team_name']?.toString() ?? 'User Team',
            entryFee: (json['entry_fee'] ?? 0).toDouble(),
            joinedAt: DateTime.fromMillisecondsSinceEpoch(json['joined_at'] ?? DateTime.now().millisecondsSinceEpoch),
            contestName: json['match_title'] ?? 'Contest',
         );
      }).toList();

      state = contests;
    } catch (e) {
      debugPrint("❌ Error fetching joined contests from D1: $e");
    }
  }

  Future<void> joinContest(UserContestEntity contest) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    try {
      final payload = {
        'userId': user.uid,
        'contestId': contest.contestId,
        'matchId': contest.matchId,
        'teamName': contest.teamName,
        'teamId': contest.teamId,
        'playerIds':  [], 
      };

      final apiService = ref.read(rapidApiServiceProvider); 
      final result = await apiService.joinContest(payload);

      if (result['success'] != true) {
         throw Exception(result['error'] ?? "Failed to join contest via Server");
      }

      // Success - update local state and balance
      await _fetchJoinedContests();
      ref.read(walletBalanceProvider.notifier).refresh();

    } catch (e) {
      debugPrint("❌ Join Contest Failed: $e");
      rethrow; 
    }
  }

  List<UserContestEntity> getContestsForMatch(String matchId) {
    return state.where((c) => c.matchId == matchId).toList();
  }
}

final userContestProvider = NotifierProvider<UserContestNotifier, List<UserContestEntity>>(() {
  return UserContestNotifier();
});
