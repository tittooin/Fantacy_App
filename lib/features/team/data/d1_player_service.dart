
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/core/api/fantasy_api_client.dart';
import 'package:axevora11/features/team/domain/player_model.dart';

final d1PlayerServiceProvider = Provider((ref) => D1PlayerService(ref.read(fantasyApiClientProvider)));

class D1PlayerService {
  final FantasyApiClient _apiClient;

  D1PlayerService(this._apiClient);

  Future<List<PlayerModel>> getPlayers(String matchId) async {
    try {
      final data = await _apiClient.getSquads(matchId);
      if (data == null || data['success'] != true) {
        return [];
      }

      List<dynamic> allPlayers = [];
      
      // Handle Team A
      if (data['teamA'] != null) {
        allPlayers.addAll(data['teamA']);
      }
      
      // Handle Team B
      if (data['teamB'] != null) {
        allPlayers.addAll(data['teamB']);
      }

      // Handle Flat List (fallback)
      if (allPlayers.isEmpty && data['players'] != null) {
        allPlayers = List.from(data['players']);
      }

      return allPlayers.map((item) {
        final json = Map<String, dynamic>.from(item);
        
        // 1. Extremely Robust Double Parser (Credits/Points)
        double parseDouble(dynamic val) {
          if (val == null) return 0.0;
          if (val is num) return val.toDouble();
          return double.tryParse(val.toString()) ?? 0.0;
        }

        // 2. Sanitization & Mapping
        final sanitized = {
          'id': (json['id'] ?? json['player_id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
          'name': (json['name'] ?? json['player_name'] ?? 'Unknown Player').toString(),
          'role': (json['role'] ?? json['player_role'] ?? 'BAT').toString().toUpperCase(),
          'credits': parseDouble(json['credits']),
          'points': parseDouble(json['points'] ?? json['fantasy_points']),
          'imageUrl': (json['imageUrl'] ?? json['image_url'] ?? json['player_image'] ?? '').toString(),
          'isPlaying': json['isPlaying'] == true || json['is_playing'] == true || json['in_starting_lineup'] == true,
          'teamId': (json['teamId'] ?? json['team_id'] ?? '').toString(),
          'teamShortName': json['teamShortName'] ?? json['team_short_name'] ?? json['team_name'],
        };

        // DEBUG: Log if crucial fields are missing or suspicious
        if (sanitized['credits'] == 0.0) {
           print("⚠️ D1 Service: Player ${sanitized['name']} has 0.0 credits. Raw: ${json['credits']}");
        }

        return PlayerModel.fromJson(sanitized);
      }).toList();

    } catch (e) {
      print("Error fetching players from D1 for match $matchId: $e");
      return [];
    }
  }
}
