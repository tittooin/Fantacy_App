import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';

abstract class MatchRepository {
  Future<void> addMatch(CricketMatchModel match);
}

class FirestoreMatchRepository implements MatchRepository {
  final FirebaseFirestore _firestore;

  FirestoreMatchRepository(this._firestore);

  @override
  Future<void> addMatch(CricketMatchModel match) async {
    try {
      print("Attempting to write match ${match.id} to Firestore...");
      // Use match ID as the document ID to prevent duplicates
      await _firestore.collection('matches').doc(match.id.toString()).set(match.toJson());
      print("Successfully wrote match ${match.id} to Firestore.");
    } catch (e) {
      print("FATAL ERROR writing to Firestore: $e");
      rethrow;
    }
  }
}

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return FirestoreMatchRepository(FirebaseFirestore.instance);
});
