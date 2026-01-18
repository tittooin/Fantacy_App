import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/team/domain/team_entity.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeamNotifier extends Notifier<List<TeamEntity>> {
  @override
  @override
  List<TeamEntity> build() {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser != null) {
      _fetchTeams();
    } else {
       FirebaseAuth.instance.authStateChanges().listen((user) {
         if (user != null) _fetchTeams();
       });
    }
    return [];
  }

  Future<void> _fetchTeams() async {
    try {
       final user = FirebaseAuth.instance.currentUser;
       if (user == null) return;

       final snapshot = await FirebaseFirestore.instance
           .collection('teams')
           .where('userId', isEqualTo: user.uid)
           .get();

       final teams = snapshot.docs.map((doc) => TeamEntity.fromMap(doc.data())).toList();
       state = teams; 
    } catch (e) {
      print("Error fetching teams: $e");
    }
  }

  Future<void> addTeam(TeamEntity team) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
         // Fallback for testing/unauth
         state = [...state, team];
         return;
      }
      
      // Ensure team has correct userId
      final teamToSave = TeamEntity(
         id: team.id, 
         matchId: team.matchId, 
         userId: user.uid, 
         players: team.players, 
         captainId: team.captainId, 
         viceCaptainId: team.viceCaptainId, 
         totalPoints: team.totalPoints, 
         teamName: team.teamName
      );

      await FirebaseFirestore.instance.collection('teams').doc(team.id).set(teamToSave.toMap());
      
      state = [...state, teamToSave];
    } catch (e) {
      print("Error saving team: $e");
      // Optionally rethrow or show error
    }
  }

  List<TeamEntity> getTeamsForMatch(String matchId) {
    return state.where((t) => t.matchId == matchId).toList();
  }
}

final teamProvider = NotifierProvider<TeamNotifier, List<TeamEntity>>(() {
  return TeamNotifier();
});
