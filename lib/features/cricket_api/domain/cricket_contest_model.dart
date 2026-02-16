
class CricketContestModel {
  final String id;
  final String matchId;
  final double entryFee;
  final int totalSpots;
  final int filledSpots;
  final double prizePool;
  final String category;
  final bool isGuaranteed;
  final bool isFlexible;
  final List<dynamic> winningBreakdown;
  final DateTime createdAt;

  CricketContestModel({
    required this.id,
    required this.matchId,
    required this.entryFee,
    required this.totalSpots,
    required this.filledSpots,
    required this.prizePool,
    required this.category,
    this.isGuaranteed = false,
    this.isFlexible = false,
    this.winningBreakdown = const [],
    required this.createdAt,
  });

  factory CricketContestModel.fromJson(Map<String, dynamic> json) {
    return CricketContestModel(
      id: json['id']?.toString() ?? '',
      matchId: (json['matchId'] ?? json['match_id'] ?? '').toString(),
      entryFee: (json['entryFee'] ?? 0).toDouble(),
      totalSpots: (json['totalSpots'] ?? 0),
      filledSpots: (json['filledSpots'] ?? 0),
      prizePool: (json['prizePool'] ?? 0).toDouble(),
      category: (json['category'] ?? '').toString(),
      winningBreakdown: json['winningBreakdown'] as List<dynamic>? ?? [],
      createdAt: DateTime.now(),
    );
  }

  factory CricketContestModel.fromFirestore(Map<String, dynamic> data, String id) {
    return CricketContestModel.fromJson({...data, 'id': id});
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'matchId': matchId,
    'entryFee': entryFee,
    'totalSpots': totalSpots,
    'filledSpots': filledSpots,
    'prizePool': prizePool,
    'category': category,
    'isGuaranteed': isGuaranteed,
    'isFlexible': isFlexible,
    'winningBreakdown': winningBreakdown,
  };
}
