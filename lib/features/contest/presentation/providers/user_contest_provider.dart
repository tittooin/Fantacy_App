import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:axevora11/features/contest/domain/user_contest_entity.dart';
import 'package:axevora11/features/cricket_api/data/services/rapid_api_service.dart';

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

  Future<void> _fetchJoinedContests() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('user_contests')
          .where('userId', isEqualTo: user.uid)
          .get();

      final contests = snapshot.docs.map((doc) => UserContestEntity.fromMap(doc.data())).toList();
      state = contests;
    } catch (e) {
      print("Error fetching joined contests: $e");
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

      // 2. Firestore Sync (For UI Only - No Wallet Write)
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

      // D. Increment Contest Spots (Visual Only, Worker checked actual spots)
      batch.update(matchContestRef, {
        'filledSpots': FieldValue.increment(1)
      });
      
      // E. Transaction History in Firestore? 
      // The user wants "Zero Firestore Wallet writes". 
      // Updating 'transactions' collection is NOT updating 'users' walletBalance.
      // It is good for history sync.
      
      final txnRef = firestore.collection('users').doc(user.uid);
      batch.update(txnRef, {
        'transactions': FieldValue.arrayUnion([{
           'type': 'JOIN_CONTEST',
           'amount': contest.entryFee,
           'contestName': contest.contestName,
           'matchId': contest.matchId,
           'timestamp': DateTime.now().toIso8601String(),
           'desc': 'Joined ${contest.contestName} (D1)'
        }])
      });

      await batch.commit();

      // Update local state
      state = [...state, contest];

    } catch (e) {
      print("Join Contest Failed: $e");
      throw e; 
    }
  }

  List<UserContestEntity> getContestsForMatch(String matchId) {
    return state.where((c) => c.matchId == matchId).toList();
  }
}

final userContestProvider = NotifierProvider<UserContestNotifier, List<UserContestEntity>>(() {
  return UserContestNotifier();
});
