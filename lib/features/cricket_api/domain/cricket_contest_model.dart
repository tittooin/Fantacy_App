
class CricketRoomModel {
  final String id;
  final String matchId;
  final double accessUsage;
  final int totalParticipants;
  final int filledParticipants;
  final String hostBenefitsInfo;
  final String category;
  final bool interactionUnlocked;
  final bool canParticipate;
  final List<dynamic> benefitTiers;
  final DateTime createdAt;

  CricketRoomModel({
    required this.id,
    required this.matchId,
    required this.accessUsage,
    required this.totalParticipants,
    required this.filledParticipants,
    required this.hostBenefitsInfo,
    required this.category,
    this.interactionUnlocked = false,
    this.canParticipate = false,
    this.benefitTiers = const [],
    required this.createdAt,
  });

  factory CricketRoomModel.fromJson(Map<String, dynamic> json) {
    return CricketRoomModel(
      id: json['id']?.toString() ?? '',
      matchId: (json['matchId'] ?? json['match_id'] ?? '').toString(),
      accessUsage: (json['accessUsage'] ?? json['entryFee'] ?? 0).toDouble(),
      totalParticipants: (json['totalParticipants'] ?? json['totalSpots'] ?? 0),
      filledParticipants: (json['filledParticipants'] ?? json['filledSpots'] ?? 0),
      hostBenefitsInfo: json['hostBenefitsInfo']?.toString() ?? "Participants may be eligible for community-shared non-monetary benefits at the host's discretion.",
      category: (json['category'] ?? '').toString(),
      benefitTiers: json['benefitTiers'] as List<dynamic>? ?? [],
      createdAt: DateTime.now(),
      interactionUnlocked: json['interactionUnlocked'] ?? false,
      canParticipate: json['canParticipate'] ?? true,
    );
  }

  factory CricketRoomModel.fromFirestore(Map<String, dynamic> data, String id) {
    return CricketRoomModel.fromJson({...data, 'id': id});
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'matchId': matchId,
    'accessUsage': accessUsage,
    'totalParticipants': totalParticipants,
    'filledParticipants': filledParticipants,
    'hostBenefitsInfo': hostBenefitsInfo,
    'category': category,
    'interactionUnlocked': interactionUnlocked,
    'canParticipate': canParticipate,
    'benefitTiers': benefitTiers,
  };
}
