import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:axevora11/features/contest/domain/user_contest_entity.dart';

class UserContestNotifier extends Notifier<List<UserContestEntity>> {
  @override
  List<UserContestEntity> build() {
    // Listen to auth changes. When user logs in, fetch data.
    // We use a stream to trigger rebuilds or just side-effect fetch
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser != null) {
      _fetchJoinedContests();
    } else {
       // Setup listener for future login if currently null
       FirebaseAuth.instance.authStateChanges().listen((user) {
         if (user != null) _fetchJoinedContests();
       });
    }
    return [];
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
      await firestore.runTransaction((transaction) async {
        final userRef = firestore.collection('users').doc(user.uid);
        final matchContestRef = firestore.collection('matches')
            .doc(contest.matchId).collection('contests').doc(contest.contestId);
        final userContestRef = firestore.collection('user_contests').doc(contest.id);

        // 1. Read User Balance
        final userSnapshot = await transaction.get(userRef);
        if (!userSnapshot.exists) throw Exception("User record not found");
        
        final double currentBalance = (userSnapshot.data()?['walletBalance'] ?? 0.0).toDouble();
        final double entryFee = contest.entryFee;

        if (currentBalance < entryFee) {
          throw Exception("Insufficient Balance");
        }

        // 2. Read Contest Spots (Safety Check)
        final contestSnapshot = await transaction.get(matchContestRef);
        final currentFilled = (contestSnapshot.data()?['filledSpots'] as num?)?.toInt() ?? 0;
        final totalSpots = (contestSnapshot.data()?['totalSpots'] as num?)?.toInt() ?? 0;
        
        if (totalSpots > 0 && currentFilled >= totalSpots) {
           throw Exception("Contest Full");
        }

        // 3. Writes
        // A. Deduct Balance & Add Transaction History
        final newBalance = currentBalance - entryFee;
        transaction.update(userRef, {
          'walletBalance': newBalance,
          'transactions': FieldValue.arrayUnion([{
             'type': 'JOIN_CONTEST',
             'amount': entryFee,
             'contestName': contest.contestName,
             'matchId': contest.matchId,
             'timestamp': DateTime.now().toIso8601String(),
             'desc': 'Joined ${contest.contestName}'
          }])
        });

        // B. Create User Contest Entry
        transaction.set(userContestRef, contest.toMap());

        // C. Create Public Leaderboard Entry
        final leaderboardRef = firestore.collection('matches')
            .doc(contest.matchId).collection('contests').doc(contest.contestId)
            .collection('entries').doc(user.uid);
            
        final userName = userSnapshot.data()?['displayName'] ?? "Player ${user.phoneNumber?.substring(user.phoneNumber!.length - 4) ?? 'User'}";

        transaction.set(leaderboardRef, {
          'userId': user.uid,
          'teamId': contest.teamId, // Added critical field for scoring
          'displayName': userName,
          'teamName': contest.teamName,
          'points': 0.0,
          'rank': 0,
          'joinedAt': DateTime.now().toIso8601String(),
        });

        // D. Increment Contest Spots
        transaction.update(matchContestRef, {
          'filledSpots': FieldValue.increment(1)
        });
      });

      // Update local state on success
      state = [...state, contest];

    } catch (e) {
      print("Transaction failed: $e");
      throw e; // Propagate error to UI
    }
  }

  List<UserContestEntity> getContestsForMatch(String matchId) {
    return state.where((c) => c.matchId == matchId).toList();
  }
}

final userContestProvider = NotifierProvider<UserContestNotifier, List<UserContestEntity>>(() {
  return UserContestNotifier();
});
