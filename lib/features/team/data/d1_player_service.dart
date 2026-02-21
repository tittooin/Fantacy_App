import 'dart:convert';

import 'package:axevora11/core/api/fantasy_api_client.dart';
import 'package:axevora11/features/team/domain/player_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final d1PlayerServiceProvider =
    Provider((ref) => D1PlayerService(ref.read(fantasyApiClientProvider)));

class D1PlayerService {
  final FantasyApiClient _apiClient;

  D1PlayerService(this._apiClient);

  Future<List<PlayerModel>> getPlayers(
    String matchId, {
    String? team1Id,
    String? team2Id,
    String? team1ShortName,
    String? team2ShortName,
  }) async {
    try {
      print('[D1_PLAYERS] Requesting squads for matchId=$matchId');
      final data = await _apiClient.getSquads(matchId);

      if (data == null || data['success'] != true) {
        return [];
      }

      // Exact response log for UI parsing audit.
      print('[SQUADS_API_RAW_JSON][$matchId] ${jsonEncode(data)}');

      final teamABucket = data['teamA'] is Iterable
          ? List<dynamic>.from(data['teamA'] as Iterable)
          : const <dynamic>[];
      final teamBBucket = data['teamB'] is Iterable
          ? List<dynamic>.from(data['teamB'] as Iterable)
          : const <dynamic>[];

      print(
        '[SQUADS_API_COUNTS][$matchId] teamA=${teamABucket.length} teamB=${teamBBucket.length}',
      );

      final uniquePlayers = <String, PlayerModel>{};

      final parsedTeamA = _parseBucket(
        bucket: teamABucket,
        bucketName: 'teamA',
        bucketCode: 'A',
        teamIdFallback: (team1Id ?? '').trim(),
        shortNameFallback: (team1ShortName ?? '').trim(),
      );
      final parsedTeamB = _parseBucket(
        bucket: teamBBucket,
        bucketName: 'teamB',
        bucketCode: 'B',
        teamIdFallback: (team2Id ?? '').trim(),
        shortNameFallback: (team2ShortName ?? '').trim(),
      );

      for (final player in [...parsedTeamA, ...parsedTeamB]) {
        uniquePlayers[player.id] = player;
      }

      return uniquePlayers.values.toList();
    } catch (e) {
      print('[D1_PLAYERS_ERROR] $e');
      return [];
    }
  }

  List<PlayerModel> _parseBucket({
    required List<dynamic> bucket,
    required String bucketName,
    required String bucketCode,
    required String teamIdFallback,
    required String shortNameFallback,
  }) {
    final parsed = <PlayerModel>[];

    for (final item in bucket) {
      try {
        if (item == null) continue;
        final json = Map<String, dynamic>.from(item);

        final id = _firstNonEmpty([
          json['id'],
          json['player_id'],
        ]);
        if (id.isEmpty) continue;

        final roleEnum = _parseRole(json['role'], id);
        if (roleEnum == PlayerRole.unknown) {
          print(
            '[SQUADS_PARSE_SKIP][$bucketName] unknown role id=$id name=${json['name']}',
          );
          continue;
        }

        // Mapping priority requested by spec:
        // team_id -> teamId -> team
        final rawTeamId = _firstNonEmpty([
          json['team_id'],
          json['teamId'],
          json['team'],
        ]);
        var normalizedTeamId = rawTeamId;
        if (teamIdFallback.isNotEmpty &&
            (normalizedTeamId.isEmpty || normalizedTeamId != teamIdFallback)) {
          // Bucket context is authoritative for UI split.
          normalizedTeamId = teamIdFallback;
        }

        final normalizedShortName = _firstNonEmpty([
          json['team_short_name'],
          json['teamShortName'],
          json['teamCode'],
          shortNameFallback,
        ]);

        parsed.add(
          PlayerModel(
            id: id,
            name: _firstNonEmpty([json['name'], 'Unknown']),
            role: roleEnum,
            credits: _parseDouble(json['credits']),
            points: _parseDouble(json['points']),
            fantasyRating: _parseDouble(json['fantasy_rating']),
            imageUrl: _firstNonEmpty([json['imageUrl'], json['image_url']]),
            isPlaying: json['isPlaying'] == true || json['is_playing'] == true,
            teamId: normalizedTeamId.isEmpty ? null : normalizedTeamId,
            teamShortName:
                normalizedShortName.isEmpty ? null : normalizedShortName,
            teamBucket: bucketCode,
          ),
        );
      } catch (e) {
        print('[SQUADS_PARSE_ERROR][$bucketName] $e');
      }
    }

    print('[SQUADS_PARSED][$bucketName] count=${parsed.length}');
    return parsed;
  }

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return '';
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  PlayerRole _parseRole(dynamic role, String playerId) {
    final raw = role?.toString().trim().toUpperCase() ?? '';
    if (raw == 'WK' || raw == 'WICKETKEEPER' || raw == 'WICKET KEEPER') {
      return PlayerRole.wicketKeeper;
    }
    if (raw == 'BAT' || raw == 'BATSMAN') {
      return PlayerRole.batsman;
    }
    if (raw == 'AR' || raw == 'ALLROUNDER' || raw == 'ALL ROUNDER') {
      return PlayerRole.allRounder;
    }
    if (raw == 'BOWL' || raw == 'BOWLER') {
      return PlayerRole.bowler;
    }
    print('[ROLE_PARSE_ERROR] id=$playerId rawRole=$raw');
    return PlayerRole.unknown;
  }
}
