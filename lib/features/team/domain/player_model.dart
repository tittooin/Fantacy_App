import 'package:freezed_annotation/freezed_annotation.dart';


// Trigger rebuild
part 'player_model.freezed.dart';
part 'player_model.g.dart';

@JsonEnum()
enum PlayerRole {
  @JsonValue('WK') wicketKeeper,
  @JsonValue('BAT') batsman,
  @JsonValue('AR') allRounder,
  @JsonValue('BOWL') bowler,
  @JsonValue('UNKNOWN') unknown
}

@freezed
abstract class PlayerModel with _$PlayerModel {
  const factory PlayerModel({
    required String id,
    required String name,
    String? teamShortName, // e.g., "CSK" - Nullable to handle legacy data
    required PlayerRole role, // Enum for strict filtering
    required double credits, // e.g., 9.0
    required String imageUrl, // URL or asset path
    @Default(0.0) double points, // Last match points or average
    @Default(0.0) double fantasyRating, // NEW: Selection Helper (0-100)
    @Default(false) bool isPlaying, // For lineup announcement
    String? teamId, // Added for robust team matching
  }) = _PlayerModel;

  factory PlayerModel.fromJson(Map<String, dynamic> json) => _$PlayerModelFromJson(json);
}
