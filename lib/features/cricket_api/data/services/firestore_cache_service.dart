import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirestoreCacheService {
  final FirebaseFirestore _firestore;

  FirestoreCacheService(this._firestore);

  /// Saves matches to Firestore (Single Source of Truth)
  Future<void> saveMatches(List<CricketMatchModel> matches, String category) async {
    if (matches.isEmpty) return;

    final batch = _firestore.batch();
    for (var match in matches) {
      final docRef = _firestore.collection('matches').doc(match.id.toString());
      final data = match.toJson();
      data['fetchedAt'] = FieldValue.serverTimestamp();
      data['category'] = category; // live, upcoming
      
      batch.set(docRef, data, SetOptions(merge: true));
    }

    try {
      await batch.commit();
      debugPrint("✅ [Firestore] Cached ${matches.length} matches ($category)");
    } catch (e) {
      debugPrint("❌ Firestore Cache Error: $e");
    }
  }
}

final firestoreCacheServiceProvider = Provider<FirestoreCacheService>((ref) {
  return FirestoreCacheService(FirebaseFirestore.instance);
});
