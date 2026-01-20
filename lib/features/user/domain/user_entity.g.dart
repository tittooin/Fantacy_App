// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserEntity _$UserEntityFromJson(Map<String, dynamic> json) => _UserEntity(
  uid: json['uid'] as String,
  email: json['email'] as String?,
  phoneNumber: json['phoneNumber'] as String?,
  displayName: json['displayName'] as String?,
  photoUrl: json['photoUrl'] as String?,
  bio: json['bio'] as String?,
  selectedState: json['selectedState'] as String?,
  isRestricted: json['isRestricted'] as bool? ?? false,
  isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
  isEmailVerified: json['isEmailVerified'] as bool? ?? false,
  isKYCVerified: json['isKYCVerified'] as bool? ?? false,
  walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0,
  bonusBalance: (json['bonusBalance'] as num?)?.toDouble() ?? 0,
  winningBalance: (json['winningBalance'] as num?)?.toDouble() ?? 0,
  followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
  followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
  contestsPlayed: (json['contestsPlayed'] as num?)?.toInt() ?? 0,
  contestsWon: (json['contestsWon'] as num?)?.toInt() ?? 0,
  createdAt: const TimestampConverter().fromJson(
    json['createdAt'] as Timestamp?,
  ),
  lastLoginAt: const TimestampConverter().fromJson(
    json['lastLoginAt'] as Timestamp?,
  ),
);

Map<String, dynamic> _$UserEntityToJson(_UserEntity instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'email': instance.email,
      'phoneNumber': instance.phoneNumber,
      'displayName': instance.displayName,
      'photoUrl': instance.photoUrl,
      'bio': instance.bio,
      'selectedState': instance.selectedState,
      'isRestricted': instance.isRestricted,
      'isPhoneVerified': instance.isPhoneVerified,
      'isEmailVerified': instance.isEmailVerified,
      'isKYCVerified': instance.isKYCVerified,
      'walletBalance': instance.walletBalance,
      'bonusBalance': instance.bonusBalance,
      'winningBalance': instance.winningBalance,
      'followersCount': instance.followersCount,
      'followingCount': instance.followingCount,
      'contestsPlayed': instance.contestsPlayed,
      'contestsWon': instance.contestsWon,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'lastLoginAt': const TimestampConverter().toJson(instance.lastLoginAt),
    };
