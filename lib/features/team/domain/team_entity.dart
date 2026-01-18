import 'package:axevora11/features/team/domain/player_model.dart';

class TeamEntity {
  final String id;
  final String matchId;
  final String userId;
  final List<PlayerModel> players;
  final String captainId;
  final String viceCaptainId;
  final double totalPoints;
  final String teamName;

  const TeamEntity({
    required this.id,
    required this.matchId,
    required this.userId,
    required this.players,
    required this.captainId,
    required this.viceCaptainId,
    required this.totalPoints,
    required this.teamName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matchId': matchId,
      'userId': userId,
      'players': players.map((p) => p.toJson()).toList(),
      'captainId': captainId,
      'viceCaptainId': viceCaptainId,
      'totalPoints': totalPoints,
      'teamName': teamName,
    };
  }

  factory TeamEntity.fromMap(Map<String, dynamic> map) {
    return TeamEntity(
      id: map['id'] ?? '',
      matchId: map['matchId'] ?? '',
      userId: map['userId'] ?? '',
      players: List<PlayerModel>.from(map['players']?.map((x) => PlayerModel.fromJson(x)) ?? []),
      captainId: map['captainId'] ?? '',
      viceCaptainId: map['viceCaptainId'] ?? '',
      totalPoints: (map['totalPoints'] ?? 0.0).toDouble(),
      teamName: map['teamName'] ?? '',
    );
  }
}
