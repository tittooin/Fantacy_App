
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/core/api/fantasy_api_client.dart';
import 'package:axevora11/features/team/domain/player_model.dart';

final d1PlayerServiceProvider = Provider((ref) => D1PlayerService(ref.read(fantasyApiClientProvider)));

// ... imports

class D1PlayerService {
  final FantasyApiClient _apiClient;

  D1PlayerService(this._apiClient);

  Future<List<PlayerModel>> getPlayers(String matchId) async {
    try {
      print("🔍 D1 Service: Requesting players for Match ID: $matchId");
      final data = await _apiClient.getSquads(matchId);
      
      if (data == null || data['success'] != true) {
        return [];
      }

      List<dynamic> allPlayers = [];
      if (data['teamA'] is Iterable) allPlayers.addAll(data['teamA']);
      if (data['teamB'] is Iterable) allPlayers.addAll(data['teamB']);

      // Deduplication Map
      final uniquePlayers = <String, PlayerModel>{};

      for (var item in allPlayers) {
        try {
          if (item == null) continue;
          final json = Map<String, dynamic>.from(item);
          
          double parseDouble(dynamic val) {
            if (val == null) return 0.0;
            if (val is num) return val.toDouble();
            return double.tryParse(val.toString()) ?? 0.0;
          }

          // TRUST BACKEND NORMALIZATION + EXTRA SAFETY FOR UI
          PlayerRole parseRole(dynamic r) {
            final roleStr = (r ?? 'BAT').toString().toUpperCase();
            if (roleStr == 'WK' || roleStr.contains('WICKET') || roleStr.contains('KEEPER')) return PlayerRole.wicketKeeper;
            if (roleStr == 'BAT' || roleStr.contains('BATS')) return PlayerRole.batsman;
            if (roleStr == 'AR' || roleStr.contains('ALL') || roleStr.contains('ROUND')) return PlayerRole.allRounder;
             if (roleStr == 'BOWL' || roleStr.contains('BOWL')) return PlayerRole.bowler;
            return PlayerRole.batsman; // Fallback
          }
          
          final roleEnum = parseRole(json['role']);

          final id = (json['id'] ?? json['player_id'] ?? '').toString();
          if (id.isEmpty) continue;

          final player = PlayerModel(
            id: id,
            name: (json['name'] ?? 'Unknown').toString(),
            role: roleEnum, // Enum
            credits: parseDouble(json['credits']),
            points: parseDouble(json['points']),
            fantasyRating: parseDouble(json['fantasy_rating']), // NEW
            imageUrl: (json['imageUrl'] ?? '').toString(),
            isPlaying: json['isPlaying'] == true,
            teamId: (json['teamId'] ?? '').toString(),
            teamShortName: (json['teamShortName'] ?? '').toString(),
          );

          uniquePlayers[id] = player; // Overwrite duplicates (last wins) or check?
          // Backend sorts T1 then T2? No, backend sorts by Role.
          // If duplicate exists, it's the same player.
          
        } catch (e) {
          print("⚠️ Player Parse Error: $e");
        }
      }

      return uniquePlayers.values.toList();

    } catch (e, stack) {
      print("❌ D1 Service Error: $e");
      return [];
    }
  }
}
