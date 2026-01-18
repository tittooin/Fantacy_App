// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contest_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ContestModel _$ContestModelFromJson(Map<String, dynamic> json) =>
    _ContestModel(
      id: json['id'] as String,
      matchId: (json['matchId'] as num).toInt(),
      entryFee: (json['entryFee'] as num).toDouble(),
      totalSpots: (json['totalSpots'] as num).toInt(),
      filledSpots: (json['filledSpots'] as num).toInt(),
      prizePool: (json['prizePool'] as num).toDouble(),
      category: json['category'] as String,
      isGuaranteed: json['isGuaranteed'] as bool? ?? false,
      isFlexible: json['isFlexible'] as bool? ?? false,
      winningBreakdown:
          (json['winningBreakdown'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ContestModelToJson(_ContestModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'matchId': instance.matchId,
      'entryFee': instance.entryFee,
      'totalSpots': instance.totalSpots,
      'filledSpots': instance.filledSpots,
      'prizePool': instance.prizePool,
      'category': instance.category,
      'isGuaranteed': instance.isGuaranteed,
      'isFlexible': instance.isFlexible,
      'winningBreakdown': instance.winningBreakdown,
      'createdAt': instance.createdAt.toIso8601String(),
    };
