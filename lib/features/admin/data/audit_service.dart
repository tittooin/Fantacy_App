import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> logAction({
    required String action, // e.g., 'ARCHIVE_MATCH', 'POLL_API', 'START_MATCH'
    required String matchId,
    Map<String, dynamic>? details,
  }) async {
    try {
      final user = _auth.currentUser;
      final adminId = user?.uid ?? 'unknown';
      
      await _firestore.collection('admin_logs').add({
        'action': action,
        'matchId': matchId,
        'adminId': adminId,
        'timestamp': FieldValue.serverTimestamp(),
        'details': details ?? {},
      });
      debugPrint("AUDIT LOG: $action for Match $matchId");
    } catch (e) {
      debugPrint("AUDIT ERROR: Failed to log action - $e");
    }
  }

  Future<void> saveApiSnapshot({
    required String matchId,
    required Map<String, dynamic> rawData,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      await _firestore
          .collection('api_snapshots')
          .doc(matchId)
          .collection('updates')
          .doc(timestamp)
          .set({
        'timestamp': FieldValue.serverTimestamp(),
        'rawResponse': rawData,
        'adminId': _auth.currentUser?.uid ?? 'system',
      });
       debugPrint("SNAPSHOT SAVED: Match $matchId at $timestamp");
    } catch (e) {
      debugPrint("SNAPSHOT ERROR: Failed to save snapshot - $e");
    }
  }
}

final auditProvider = AuditService();
