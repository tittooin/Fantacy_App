
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
        print("⚠️ D1 Service: No data or success=false for match $matchId");
        return [];
      }

      List<dynamic> allPlayers = [];
      
      // Safe Extract Team A
      if (data['teamA'] is Iterable) {
        allPlayers.addAll(data['teamA']);
      } else if (data['team1_players'] is Iterable) {
        allPlayers.addAll(data['team1_players']);
      }
      
      // Safe Extract Team B
      if (data['teamB'] is Iterable) {
        allPlayers.addAll(data['teamB']);
      } else if (data['team2_players'] is Iterable) {
        allPlayers.addAll(data['team2_players']);
      }

      // Safe Extract Flat List
      if (allPlayers.isEmpty && data['players'] is Iterable) {
        allPlayers = List.from(data['players']);
      }

      print("🔍 D1 Service: Found ${allPlayers.length} total players for match $matchId");

      return allPlayers.map((item) {
        try {
          if (item == null) return null;
          final json = Map<String, dynamic>.from(item);
          
          // 1. Double Parser
          double parseDouble(dynamic val) {
            if (val == null) return 0.0;
            if (val is num) return val.toDouble();
            final parsed = double.tryParse(val.toString());
            return parsed ?? 0.0;
          }

          // 2. Role Normalization (Translate full names to codes)
          String normalizeRole(dynamic r) {
            final role = (r ?? 'BAT').toString().toUpperCase();
            if (role == 'WK' || role.contains('WICKET') || role.contains('KEEPER')) return 'WK';
            if (role == 'BAT' || role.contains('BATS')) return 'BAT';
            if (role == 'AR' || role.contains('ALL') || role.contains('ROUND')) return 'AR';
            if (role == 'BOWL' || role.contains('BOWL')) return 'BOWL';
            return 'BAT';
          }

          // 3. Image Proxy (CORS Fix)
          String getProxiedUrl(String original) {
            if (original.isEmpty) return '';
            if (original.contains('fantasy-cricket-api')) return original; // Already proxied
            const workerUrl = 'https://fantasy-cricket-api.moremagical4.workers.dev';
            return '$workerUrl/api/player-image?url=${Uri.encodeComponent(original)}';
          }

          // 4. Sanitizaton
          final sanitized = {
            'id': (json['id'] ?? json['player_id'] ?? json['uid'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
            'name': (json['name'] ?? json['player_name'] ?? 'Unknown Player').toString(),
            'role': normalizeRole(json['role'] ?? json['player_role']),
            'credits': parseDouble(json['credits']),
            'points': parseDouble(json['fantasy_points'] ?? json['points']),
            'imageUrl': getProxiedUrl((json['imageUrl'] ?? json['image_url'] ?? json['player_image'] ?? '').toString()),
            'isPlaying': json['isPlaying'] == true || json['is_playing'] == true || json['in_starting_lineup'] == true,
            'teamId': (json['teamId'] ?? json['team_id'] ?? '').toString(),
            'teamShortName': (json['teamShortName'] ?? json['team_short_name'] ?? json['team_name'] ?? '').toString(),
          };

          if (sanitized['teamShortName'] == 'null') sanitized['teamShortName'] = '';

          return PlayerModel.fromJson(sanitized);
        } catch (e) {
          print("⚠️ D1 Service: Failed to parse individual player: $e");
          return null;
        }
      }).whereType<PlayerModel>().toList();

    } catch (e, stack) {
      print("❌ D1 Service Error: $e");
      print(stack);
      return [];
    }
  }
}
