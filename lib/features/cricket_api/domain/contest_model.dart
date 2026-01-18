import 'package:freezed_annotation/freezed_annotation.dart';

part 'contest_model.freezed.dart';
part 'contest_model.g.dart';

@freezed
abstract class ContestModel with _$ContestModel {
  const factory ContestModel({
    required String id,
    required int matchId,
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

  factory ContestModel.fromJson(Map<String, dynamic> json) =>
      _$ContestModelFromJson(json);
      
  factory ContestModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ContestModel.fromJson({...data, 'id': id});
  }
}
