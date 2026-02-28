import 'package:axevora11/features/team/domain/player_model.dart';

class TeamEntity {
  final String id;
  final String matchId;
  final String userId;
  final List<PlayerModel> players;
  final String captainId;
  final String viceCaptainId;
  final double totalStats;
  final String teamName;
  final bool isPersisted;

  const TeamEntity({
    required this.id,
    required this.matchId,
    required this.userId,
    required this.players,
    required this.captainId,
    required this.viceCaptainId,
    required this.totalStats,
    required this.teamName,
    this.isPersisted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matchId': matchId,
      'userId': userId,
      'players': players.map((p) => p.toJson()).toList(),
      'captainId': captainId,
      'viceCaptainId': viceCaptainId,
      'totalPoints': totalStats,
      'teamName': teamName,
    };
  }

  TeamEntity copyWith({
    String? id,
    String? matchId,
    String? userId,
    List<PlayerModel>? players,
    String? captainId,
    String? viceCaptainId,
    double? totalStats,
    String? teamName,
    bool? isPersisted,
  }) {
    return TeamEntity(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      userId: userId ?? this.userId,
      players: players ?? this.players,
      captainId: captainId ?? this.captainId,
      viceCaptainId: viceCaptainId ?? this.viceCaptainId,
      totalStats: totalStats ?? this.totalStats,
      teamName: teamName ?? this.teamName,
      isPersisted: isPersisted ?? this.isPersisted,
    );
  }

  factory TeamEntity.fromMap(Map<String, dynamic> map) {
    return TeamEntity(
      id: map['id'] ?? '',
      matchId: map['matchId'] ?? '',
      userId: map['userId'] ?? '',
      players: List<PlayerModel>.from(map['players']?.map((x) => PlayerModel.fromJson(x)) ?? []),
      captainId: map['captainId'] ?? '',
      viceCaptainId: map['viceCaptainId'] ?? '',
      totalStats: (map['totalPoints'] ?? 0.0).toDouble(),
      teamName: map['teamName'] ?? '',
      isPersisted: true,
    );
  }
}
