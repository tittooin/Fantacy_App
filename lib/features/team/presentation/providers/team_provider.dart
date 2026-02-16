import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/team/domain/team_entity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:axevora11/features/cricket_api/data/services/rapid_api_service.dart';
import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'package:flutter/foundation.dart';

class TeamNotifier extends Notifier<List<TeamEntity>> {
  @override
  List<TeamEntity> build() {
    final uid = ref.watch(authUserIdProvider);
    if (uid != null) {
      _fetchTeams();
    }
    return [];
  }

  Future<void> _fetchTeams() async {
    try {
       final user = FirebaseAuth.instance.currentUser;
       if (user == null) return;

       final apiService = ref.read(rapidApiServiceProvider);
       final teamsData = await apiService.fetchTeams(user.uid);
       
       final teams = teamsData.map((data) => TeamEntity.fromMap(data)).toList();
       debugPrint("📊 TeamNotifier: Fetched ${teams.length} teams for UID: ${user.uid}");
       state = teams; 
    } catch (e) {
      debugPrint("Error fetching teams from D1: $e");
    }
  }

  Future<void> addTeam(TeamEntity team) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final apiService = ref.read(rapidApiServiceProvider);
      
      final teamData = team.toMap();
      teamData['userId'] = user.uid;
      
      final result = await apiService.saveTeam(teamData);
      debugPrint("TeamNotifier: Save Result: $result");
      
      if (result['success'] == true) {
        await _fetchTeams();
      }
    } catch (e) {
      debugPrint("Error saving team to D1: $e");
    }
  }

  List<TeamEntity> getTeamsForMatch(String matchId) {
    return state.where((t) => t.matchId == matchId).toList();
  }
}

final teamProvider = NotifierProvider<TeamNotifier, List<TeamEntity>>(() {
  return TeamNotifier();
});
