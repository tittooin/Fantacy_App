import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axevora11/features/contest/services/contest_service.dart';

class PrivateContestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ContestService _contestService = ContestService();

  Future<void> joinByInviteCode({
    required String inviteCode,
    required String userId,
    required String teamName,
    required List<String> playerIds,
    required String captainId,
    required String viceCaptainId,
  }) async {
    // 1. Find Contest by Invite Code
    final query = await _firestore.collection('contests')
        .where('inviteCode', isEqualTo: inviteCode)
        .where('type', isEqualTo: 'private')
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception("Invalid Invite Code");
    }

    final contestDoc = query.docs.first;
    final contestId = contestDoc.id;

    // 2. Delegate to standard join logic
    await _contestService.joinContest(
      contestId: contestId,
      userId: userId,
      teamName: teamName,
      playerIds: playerIds,
      captainId: captainId,
      viceCaptainId: viceCaptainId,
    );
  }
}
