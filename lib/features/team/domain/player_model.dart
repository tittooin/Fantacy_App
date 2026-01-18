import 'package:freezed_annotation/freezed_annotation.dart';


// Trigger rebuild
part 'player_model.freezed.dart';
part 'player_model.g.dart';

@freezed
abstract class PlayerModel with _$PlayerModel {
  const factory PlayerModel({
    required String id,
    required String name,
    required String teamShortName, // e.g., "CSK"
    required String role, // "WK", "BAT", "AR", "BOWL"
    required double credits, // e.g., 9.0
    required String imageUrl, // URL or asset path
    @Default(0.0) double points, // Last match points or average
    @Default(false) bool isPlaying, // For lineup announcement
  }) = _PlayerModel;

  factory PlayerModel.fromJson(Map<String, dynamic> json) => _$PlayerModelFromJson(json);
}
