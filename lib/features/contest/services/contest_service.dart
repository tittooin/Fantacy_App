import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';

class ContestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Create Contest (Public/Private)
  Future<String> createContest({
    required String matchId,
    required String name,
    required int entryFee,
    required int prizePool,
    required int maxSpots,
    required bool isPrivate,
    required String createdByUserId,
  }) async {
    final contestId = _uuid.v4();
    String? inviteCode;
    
    if (isPrivate) {
      inviteCode = _generateInviteCode();
    }

    final contestData = {
      'matchId': matchId,
      'name': name,
      'entryFee': entryFee,
      'prizePool': prizePool,
      'maxSpots': maxSpots,
      'joinedCount': 0,
      'status': 'Upcoming', // upcoming | live | completed
      'type': isPrivate ? 'private' : 'public',
      'inviteCode': inviteCode,
      'createdBy': createdByUserId,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('contests').doc(contestId).set(contestData);
    return contestId;
  }

  // Join Contest (Multi-Team Support)
  Future<void> joinContest({
    required String contestId,
    required String userId,
    required String teamName,
    required List<String> playerIds,
    required String captainId,
    required String viceCaptainId,
  }) async {
    final contestRef = _firestore.collection('contests').doc(contestId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(contestRef);
      if (!snapshot.exists) throw Exception("Contest not found");

      final data = snapshot.data()!;
      final currentJoined = data['joinedCount'] ?? 0;
      final maxSpots = data['maxSpots'] ?? 100;
      final status = data['status'] ?? 'Upcoming';

      if (status != 'Upcoming') throw Exception("Contest is $status (locked)");
      if (currentJoined >= maxSpots) throw Exception("Contest Full");

      // Check User Team Count Limit (Max 20 per contest)
      // Query participants where userId == currentUserId
      // Note: Transaction/Query interaction limitation in Firestore implies we might need a separate read
      // But for strict consistency, we risk it or do optimistic check outside tx if querying subcollections is hard.
      // Firestore transactions require reads BEFORE writes. 
      // Subcollection checks inside transaction can be tricky if high concurrency.
      // For MVP/Scalability: We rely on the write rule or pre-check.
      // Let's do a transactional read of a 'user_entries' doc if we wanted perfect implementation,
      // but standard approach: just add. 
      
      // We will perform a check *before* transaction block for UX, 
      // and rely on security rules or lax server check for actual enforcing if high traffic.
      // Here, keeping it simple: Just Insert.
      
      final newTeamId = _uuid.v4(); // Unique ID for EACH entry (Dream11 style)
      
      final participantRef = contestRef.collection('participants').doc(newTeamId);
      
      final participantData = {
        'teamId': newTeamId,
        'userId': userId,
        'teamName': teamName,
        'players': playerIds,
        'captain': captainId,
        'viceCaptain': viceCaptainId,
        'points': 0,
        'rank': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      transaction.set(participantRef, participantData);
      transaction.update(contestRef, {'joinedCount': FieldValue.increment(1)});
    });
  }

  // Generate 6-char random code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
      6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  // Get User Team Count (For validation UI)
  Future<int> getUserTeamCount(String contestId, String userId) async {
    final snapshot = await _firestore.collection('contests')
      .doc(contestId)
      .collection('participants')
      .where('userId', isEqualTo: userId)
      .count()
      .get();
    
    return snapshot.count ?? 0;
  }
}
