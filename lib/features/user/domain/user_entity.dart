import 'package:axevora11/core/utils/json_converters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';
part 'user_entity.g.dart';

@freezed
abstract class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String uid,
    String? email,
    String? phoneNumber,
    String? displayName,
    String? photoUrl,
    String? bio,
    String? selectedState,
    @Default(false) bool isRestricted,
    @Default(false) bool isPhoneVerified,
    @Default(false) bool isEmailVerified,
    @Default(false) bool isKYCVerified, // Added for Payment Security
    @Default(0) double walletBalance,
    @Default(0) double bonusBalance,
    @Default(0) double winningBalance,
    @Default(0) int followersCount,
    @Default(0) int followingCount,
    @Default(0) int contestsPlayed,
    @Default(0) int contestsWon,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? lastLoginAt,
  }) = _UserEntity;

  factory UserEntity.fromJson(Map<String, dynamic> json) => _$UserEntityFromJson(json);
}
