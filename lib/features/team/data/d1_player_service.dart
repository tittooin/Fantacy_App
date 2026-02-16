
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

          // STRICT PARSING LOGIC - NO FALLBACKS
          PlayerRole parseRole(dynamic r, String playerId) {
            final raw = r?.toString().trim().toUpperCase() ?? '';
            PlayerRole result;
            
            if (raw == 'WK' || raw == 'WICKETKEEPER' || raw == 'WICKET KEEPER') {
              result = PlayerRole.wicketKeeper;
            } else if (raw == 'BAT' || raw == 'BATSMAN') {
               result = PlayerRole.batsman;
            } else if (raw == 'AR' || raw == 'ALLROUNDER' || raw == 'ALL ROUNDER') {
               result = PlayerRole.allRounder;
            } else if (raw == 'BOWL' || raw == 'BOWLER') {
               result = PlayerRole.bowler;
            } else {
               // LOG ERROR FOR UNKNOWN ROLE
               print("❌ ROLE PARSE ERROR: ID=$playerId, RawRole='$raw' -> Defaulting to UNKNOWN");
               return PlayerRole.unknown; 
            }
            
            print("✅ ROLE PARSED: ID=$playerId, Raw='$raw', Enum=${result.displayStr}");
            return result;
          }
          
          final id = (json['id'] ?? json['player_id'] ?? '').toString();
          if (id.isEmpty) continue;

          final roleEnum = parseRole(json['role'], id);
          
          if (roleEnum == PlayerRole.unknown) {
             print("⚠️ SKIPPING PLAYER due to Unknown Role: ID=$id Name=${json['name']}");
             continue; // Strict: Don't show players with broken roles
          }

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
