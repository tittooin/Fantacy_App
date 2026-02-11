import 'package:freezed_annotation/freezed_annotation.dart';

part 'contest_model.freezed.dart';
part 'contest_model.g.dart';

@freezed
abstract class ContestModel with _$ContestModel {
  const factory ContestModel({
    required String id,
    required String matchId, // Changed from int to String to match D1
    required double entryFee,
    required int totalSpots,
    required int filledSpots,
    required double prizePool,
    required String category, // e.g., "Mega Contest", "Head 2 Head"
    @Default(false) bool isGuaranteed,
    @Default(false) bool isFlexible,
    // List of payout tiers: [{'rankStart': 1, 'rankEnd': 1, 'amount': 1000}, ...]
    @Default([]) List<Map<String, dynamic>> winningBreakdown,
    required DateTime createdAt,
  }) = _ContestModel;


  factory ContestModel.fromJson(Map<String, dynamic> json) {
    // Handle both D1 API format (created_at) and Dart format (createdAt)
    final createdAtValue = json['createdAt'] ?? json['created_at'];
    final DateTime createdAt;
    
    if (createdAtValue is int) {
      // Timestamp from D1
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtValue);
    } else if (createdAtValue is String) {
      createdAt = DateTime.parse(createdAtValue);
    } else if (createdAtValue is DateTime) {
      createdAt = createdAtValue;
    } else {
      createdAt = DateTime.now();
    }
    
    return ContestModel(
      id: json['id'].toString(),
      matchId: (json['matchId'] ?? json['match_id']).toString(),
      entryFee: (json['entryFee'] ?? json['entry_fee'] ?? 0).toDouble(),
      totalSpots: (json['totalSpots'] ?? json['total_spots'] ?? 0) as int,
      filledSpots: (json['filledSpots'] ?? json['filled_spots'] ?? 0) as int,
      prizePool: (json['prizePool'] ?? json['prize_pool'] ?? 0).toDouble(),
      category: (json['category'] ?? 'Contest').toString(),
      isGuaranteed: (json['isGuaranteed'] ?? json['is_guaranteed'] == 1 || json['is_guaranteed'] == true) as bool? ?? false,
      isFlexible: (json['isFlexible'] ?? json['is_flexible'] == 1 || json['is_flexible'] == true) as bool? ?? false,
      winningBreakdown: ((json['winningBreakdown'] ?? json['winning_breakdown'] ?? []) as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      createdAt: createdAt,
    );
  }
      
  factory ContestModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ContestModel.fromJson({...data, 'id': id});
  }
}

