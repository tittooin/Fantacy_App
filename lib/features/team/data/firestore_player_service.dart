import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axevora11/features/team/domain/player_model.dart';

class FirestorePlayerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<PlayerModel>> getPlayers(String matchId) async {
    try {
      final snapshot = await _firestore
          .collection('matches')
          .doc(matchId)
          .collection('players')
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      return snapshot.docs.map((doc) => PlayerModel.fromJson(doc.data())).toList();
    } catch (e) {
      print("Error fetching players for match $matchId: $e");
      return [];
    }
  }

  // Helper to seed players (if needed via API)
  Future<void> saveSquad(String matchId, List<PlayerModel> players) async {
    final batch = _firestore.batch();
    final squadRef = _firestore.collection('matches').doc(matchId).collection('players');

    for (var player in players) {
      final docRef = squadRef.doc(player.id);
      batch.set(docRef, player.toJson());
    }

    await batch.commit();
  }
}
