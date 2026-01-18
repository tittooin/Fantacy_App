// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlayerModel _$PlayerModelFromJson(Map<String, dynamic> json) => _PlayerModel(
  id: json['id'] as String,
  name: json['name'] as String,
  teamShortName: json['teamShortName'] as String,
  role: json['role'] as String,
  credits: (json['credits'] as num).toDouble(),
  imageUrl: json['imageUrl'] as String,
  points: (json['points'] as num?)?.toDouble() ?? 0.0,
  isPlaying: json['isPlaying'] as bool? ?? false,
);

Map<String, dynamic> _$PlayerModelToJson(_PlayerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'teamShortName': instance.teamShortName,
      'role': instance.role,
      'credits': instance.credits,
      'imageUrl': instance.imageUrl,
      'points': instance.points,
      'isPlaying': instance.isPlaying,
    };
