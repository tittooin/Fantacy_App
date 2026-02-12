import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:axevora11/features/contest/domain/user_contest_entity.dart';
import 'package:axevora11/features/cricket_api/data/services/rapid_api_service.dart';
import 'package:axevora11/features/wallet/presentation/providers/wallet_provider.dart';

class UserContestNotifier extends Notifier<List<UserContestEntity>> {
  @override
  List<UserContestEntity> build() {
    // Listen to auth changes. When user logs in, fetch data.
    // We use a stream to trigger rebuilds or just side-effect fetch
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser != null) {
      _fetchJoinedContests();
      _proactiveSyncUser(authUser);
    } else {
       // Setup listener for future login if currently null
       FirebaseAuth.instance.authStateChanges().listen((user) {
         if (user != null) {
           _fetchJoinedContests();
           _proactiveSyncUser(user);
         }
       });
    }
    return [];
  }

  /// Proactively sync user to D1 to avoid USER_NOT_FOUND during join
  void _proactiveSyncUser(User user) async {
    try {
      final apiService = ref.read(rapidApiServiceProvider);
      await apiService.syncUser(
        user.uid, 
        user.email ?? '', 
        user.displayName ?? 'User'
      );
      print('✅ Proactive sync: User ${user.uid} verified in D1');
    } catch (e) {
      print('⚠️ Proactive sync skipped/failed: $e');
    }
  }

  // Hindi: D1 se joined contests fetch karta hai
  Future<void> _fetchJoinedContests() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final apiService = ref.read(rapidApiServiceProvider);
      final list = await apiService.fetchUserJoinedContests(user.uid);

      // Convert D1 Map results to UserContestEntity
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
            contestName: json['match_title'] ?? 'Contest', // Match title shared in join
            transactionId: '',
         );
      }).toList();

      state = contests;
      debugPrint("✅ D1 → Synced ${contests.length} joined contests for User");
    } catch (e) {
      debugPrint("❌ Error fetching joined contests from D1: $e");
    }
  }

  Future<void> joinContest(UserContestEntity contest) async {
    final firestore = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    try {
      // 1. D1 Wallet Deduction (Source of Truth) via Worker API
      // We do NOT touch Firestore Wallet Balance here (Strict Compliance)
      final payload = {
        'userId': user.uid,
        'contestId': contest.contestId,
        'matchId': contest.matchId,
        'teamName': contest.teamName,
        'teamId': contest.teamId,
        'playerIds':  [], // Pass empty or fetch if needed, Worker handles "User Team" default
      };

      // We need to access RapidApiService. 
      // Ideally pass 'ref' to this Notifier or use a Provider, but Notifier has 'ref'.
      // Note: We need to import 'rapid_api_service.dart' and 'rapid_api_service_provider'.
      // Assuming imports are added. If not, I will add them in next step.
      
      // Since we are inside a Notifier, we can use 'ref'.
      // However, we need to cast 'ref' context or ensure we have access.
      // Notifier has 'ref'.
      
      // Hack: We need the provider. I'll assume import is present or I'll fix it.
      // Let's rely on adding imports separately if needed.
      
      // Actually, I'll use the API Call directly or via Repository if I had one.
      // Re-using the logic from WalletScreen approach? No, use the Service I just updated.
      // I cannot easily access the provider here without importing it.
      // I will add the import in a separate tool call if it fails, OR I can try to be safe.
      
      // Let's implement the logic assuming imports will be fixed.
      final apiService = ref.read(rapidApiServiceProvider); 
      final result = await apiService.joinContest(payload);

      if (result['success'] != true) {
         throw Exception(result['error'] ?? "Failed to join contest via Server");
      }

      // 2. Firestore Sync (For UI Only - Best Effort)
      try {
        final batch = firestore.batch();
        
        // A. Paths
        final matchContestRef = firestore.collection('contests').doc(contest.contestId);
        final userContestRef = firestore.collection('user_contests').doc(contest.id);
        final leaderboardRef = firestore.collection('contests')
              .doc(contest.contestId)
              .collection('entries').doc(user.uid);

        // B. Create User Contest Entry
        batch.set(userContestRef, contest.toMap());

        // C. Create Public Leaderboard Entry (For App UI)
        final userSnapshot = await firestore.collection('users').doc(user.uid).get();
        final data = userSnapshot.data();
        final String? storedName = data?['displayName'];
        final userName = (storedName != null && storedName.isNotEmpty) 
            ? storedName 
            : "Player ${user.phoneNumber?.substring(user.phoneNumber!.length - 4) ?? 'User'}";

        batch.set(leaderboardRef, {
          'userId': user.uid,
          'teamId': contest.teamId,
          'displayName': userName,
          'teamName': contest.teamName,
          'points': 0.0,
          'rank': 0,
          'joinedAt': DateTime.now().toIso8601String(),
        });

        // D. Increment Contest Spots (Visual Only)
        // Fix: Use set with merge: true instead of update to avoid [not-found] error if contest is missing in Firestore
        batch.set(matchContestRef, {
          'filledSpots': FieldValue.increment(1)
        }, SetOptions(merge: true));
        
        // E. Transaction History
        final txnRef = firestore.collection('users').doc(user.uid);
        batch.set(txnRef, {
          'transactions': FieldValue.arrayUnion([{
             'type': 'JOIN_CONTEST',
             'amount': contest.entryFee,
             'contestName': contest.contestName,
             'matchId': contest.matchId,
             'timestamp': DateTime.now().toIso8601String(),
             'desc': 'Joined ${contest.contestName} (D1)'
          }])
        }, SetOptions(merge: true));

        await batch.commit();
        print("✅ Firestore Sync Complete");
      } catch (fsError) {
        // We log but don't THROW because D1 already succeeded!
        print("⚠️ Firestore Sync Warning (Non-fatal): $fsError");
      }

      // Update local state
      state = [...state, contest];

      // Refresh Global Balance after deduction
      ref.read(walletBalanceProvider.notifier).refresh();

    } catch (e) {
      print("❌ Join Contest Failed: $e");
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
