import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/cricket_api/domain/contest_model.dart';
import 'package:axevora11/features/wallet/data/wallet_repository.dart';
import 'package:uuid/uuid.dart';

final resultServiceProvider = Provider((ref) => ResultService(ref));

class ResultService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ResultService(this._ref);

  Future<void> processMatchResult(String matchId) async {
    print("🏆 Starting Result Processing for Match: $matchId");

    // 1. Get all Contests for this Match
    final contestsSnapshot = await _firestore
        .collection('matches')
        .doc(matchId)
        .collection('contests')
        .get();

    for (var doc in contestsSnapshot.docs) {
      final contestData = doc.data();
      final contest = ContestModel.fromJson(contestData);
      
      print("  Processing Contest: ${contest.category} (${contest.id})");
      await _calculateContestWinners(matchId, contest);
    }

    print("✅ Result Processing Complete for Match: $matchId");
  }

  Future<void> _calculateContestWinners(String matchId, ContestModel contest) async {
    // 2. Fetch Leaderboard (Sorted by Points)
    final entriesSnapshot = await _firestore
        .collection('matches')
        .doc(matchId)
        .collection('contests')
        .doc(contest.id)
        .collection('entries')
        .orderBy('points', descending: true)
        .get();

    final entries = entriesSnapshot.docs;
    if (entries.isEmpty) return;

    // 3. Get Prize Breakdown
    // Format: [{rankStart: 1, rankEnd: 1, amount: 1000}, {rankStart: 2, rankEnd: 5, amount: 500}]
    final breakdown = contest.winningBreakdown;
    if (breakdown.isEmpty) return;

    // 4. Assign Ranks and Distribute Winnings
    int currentRank = 1;

    for (int i = 0; i < entries.length; i++) {
      final entryDoc = entries[i];
      final Map<String, dynamic> entryData = entryDoc.data();
      final userId = entryData['userId'];
      final points = entryData['points'] ?? 0;
      
      // Handle Tie Logic (Simplistic: Same points = Same rank)
      if (i > 0) {
        final prevPoints = entries[i - 1].data()['points'] ?? 0;
        if (points < prevPoints) {
          currentRank = i + 1;
        }
      }

      // Check if this rank falls in any winning tier
      double prizeAmount = 0.0;
      for (var tier in breakdown) {
        final start = tier['rankStart'] as int;
        final end = tier['rankEnd'] as int;
        final amount = (tier['amount'] as num).toDouble();

        if (currentRank >= start && currentRank <= end) {
          prizeAmount = amount;
          break;
        }
      }

      // If winner, Update Wallet
      if (prizeAmount > 0) {
        print("    🎉 User $userId (Rank $currentRank) won ₹$prizeAmount");
        await _distributeWinnings(userId, prizeAmount, matchId, contest.category);
        
        // Update Entry with Rank and Winnings
        await entryDoc.reference.update({
          'rank': currentRank,
          'winnings': prizeAmount,
          'status': 'Won'
        });
      } else {
        // Update Entry for non-winners
        await entryDoc.reference.update({
           'rank': currentRank,
           'winnings': 0,
           'status': 'Lost'
        });
      }
    }
  }

  Future<void> _distributeWinnings(String userId, double amount, String matchId, String contestName) async {
    final walletRepo = _ref.read(walletRepositoryProvider);
    
    // Add to Winnings Balance
    // Note: Transaction Logic adds to total balance. Ideally we split Deposit/Winning.
    // For MVP, we add to generic balance.
    await walletRepo.addFunds(userId, amount);
    
    // Create Transaction Record
    // Note: walletRepo.addFunds typically creates a transaction if handled internally.
    // If not, we should create one. Checking walletRepo... 
    // Assuming addFunds handles balance updates. We will manually add a "Winning" transaction log if needed.
    
    final transactionId = const Uuid().v4();
    await _firestore.collection('users').doc(userId).collection('transactions').doc(transactionId).set({
      'id': transactionId,
      'amount': amount,
      'type': 'Credit', // Credit
      'category': 'Winnings',
      'description': 'Won in $contestName',
      'matchId': matchId,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'Success'
    });
  }
}
