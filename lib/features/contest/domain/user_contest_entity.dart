class UserContestEntity {
  final String id;
  final String userId;
  final String contestId;
  final String matchId;
  final String teamId;
  final String teamName;
  final double entryFee;
  final DateTime joinedAt;
  final String contestName; // e.g. "Mega Contest"

  const UserContestEntity({
    required this.id,
    required this.userId,
    required this.contestId,
    required this.matchId,
    required this.teamId,
    required this.teamName,
    required this.entryFee,
    required this.joinedAt,
    required this.contestName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'contestId': contestId,
      'matchId': matchId,
      'teamId': teamId,
      'teamName': teamName,
      'entryFee': entryFee,
      'joinedAt': joinedAt.millisecondsSinceEpoch,
      'contestName': contestName,
    };
  }

  factory UserContestEntity.fromMap(Map<String, dynamic> map) {
    return UserContestEntity(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      contestId: map['contestId'] ?? '',
      matchId: map['matchId'] ?? '',
      teamId: map['teamId'] ?? '',
      teamName: map['teamName'] ?? '',
      entryFee: (map['entryFee'] ?? 0.0).toDouble(),
      joinedAt: DateTime.fromMillisecondsSinceEpoch(map['joinedAt'] ?? 0),
      contestName: map['contestName'] ?? 'Contest',
    );
  }
}
