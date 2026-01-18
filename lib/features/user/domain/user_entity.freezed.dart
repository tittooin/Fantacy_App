// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserEntity {

 String get uid; String? get email; String? get phoneNumber; String? get displayName; String? get photoUrl; String? get bio; String? get selectedState; bool get isRestricted; bool get isPhoneVerified; bool get isEmailVerified; double get walletBalance; double get bonusBalance; double get winningBalance; int get followersCount; int get followingCount; int get contestsPlayed; int get contestsWon;@TimestampConverter() DateTime? get createdAt;@TimestampConverter() DateTime? get lastLoginAt;
/// Create a copy of UserEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserEntityCopyWith<UserEntity> get copyWith => _$UserEntityCopyWithImpl<UserEntity>(this as UserEntity, _$identity);

  /// Serializes this UserEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserEntity&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.email, email) || other.email == email)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.selectedState, selectedState) || other.selectedState == selectedState)&&(identical(other.isRestricted, isRestricted) || other.isRestricted == isRestricted)&&(identical(other.isPhoneVerified, isPhoneVerified) || other.isPhoneVerified == isPhoneVerified)&&(identical(other.isEmailVerified, isEmailVerified) || other.isEmailVerified == isEmailVerified)&&(identical(other.walletBalance, walletBalance) || other.walletBalance == walletBalance)&&(identical(other.bonusBalance, bonusBalance) || other.bonusBalance == bonusBalance)&&(identical(other.winningBalance, winningBalance) || other.winningBalance == winningBalance)&&(identical(other.followersCount, followersCount) || other.followersCount == followersCount)&&(identical(other.followingCount, followingCount) || other.followingCount == followingCount)&&(identical(other.contestsPlayed, contestsPlayed) || other.contestsPlayed == contestsPlayed)&&(identical(other.contestsWon, contestsWon) || other.contestsWon == contestsWon)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastLoginAt, lastLoginAt) || other.lastLoginAt == lastLoginAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,uid,email,phoneNumber,displayName,photoUrl,bio,selectedState,isRestricted,isPhoneVerified,isEmailVerified,walletBalance,bonusBalance,winningBalance,followersCount,followingCount,contestsPlayed,contestsWon,createdAt,lastLoginAt]);

@override
String toString() {
  return 'UserEntity(uid: $uid, email: $email, phoneNumber: $phoneNumber, displayName: $displayName, photoUrl: $photoUrl, bio: $bio, selectedState: $selectedState, isRestricted: $isRestricted, isPhoneVerified: $isPhoneVerified, isEmailVerified: $isEmailVerified, walletBalance: $walletBalance, bonusBalance: $bonusBalance, winningBalance: $winningBalance, followersCount: $followersCount, followingCount: $followingCount, contestsPlayed: $contestsPlayed, contestsWon: $contestsWon, createdAt: $createdAt, lastLoginAt: $lastLoginAt)';
}


}

/// @nodoc
abstract mixin class $UserEntityCopyWith<$Res>  {
  factory $UserEntityCopyWith(UserEntity value, $Res Function(UserEntity) _then) = _$UserEntityCopyWithImpl;
@useResult
$Res call({
 String uid, String? email, String? phoneNumber, String? displayName, String? photoUrl, String? bio, String? selectedState, bool isRestricted, bool isPhoneVerified, bool isEmailVerified, double walletBalance, double bonusBalance, double winningBalance, int followersCount, int followingCount, int contestsPlayed, int contestsWon,@TimestampConverter() DateTime? createdAt,@TimestampConverter() DateTime? lastLoginAt
});




}
/// @nodoc
class _$UserEntityCopyWithImpl<$Res>
    implements $UserEntityCopyWith<$Res> {
  _$UserEntityCopyWithImpl(this._self, this._then);

  final UserEntity _self;
  final $Res Function(UserEntity) _then;

/// Create a copy of UserEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? email = freezed,Object? phoneNumber = freezed,Object? displayName = freezed,Object? photoUrl = freezed,Object? bio = freezed,Object? selectedState = freezed,Object? isRestricted = null,Object? isPhoneVerified = null,Object? isEmailVerified = null,Object? walletBalance = null,Object? bonusBalance = null,Object? winningBalance = null,Object? followersCount = null,Object? followingCount = null,Object? contestsPlayed = null,Object? contestsWon = null,Object? createdAt = freezed,Object? lastLoginAt = freezed,}) {
  return _then(_self.copyWith(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,selectedState: freezed == selectedState ? _self.selectedState : selectedState // ignore: cast_nullable_to_non_nullable
as String?,isRestricted: null == isRestricted ? _self.isRestricted : isRestricted // ignore: cast_nullable_to_non_nullable
as bool,isPhoneVerified: null == isPhoneVerified ? _self.isPhoneVerified : isPhoneVerified // ignore: cast_nullable_to_non_nullable
as bool,isEmailVerified: null == isEmailVerified ? _self.isEmailVerified : isEmailVerified // ignore: cast_nullable_to_non_nullable
as bool,walletBalance: null == walletBalance ? _self.walletBalance : walletBalance // ignore: cast_nullable_to_non_nullable
as double,bonusBalance: null == bonusBalance ? _self.bonusBalance : bonusBalance // ignore: cast_nullable_to_non_nullable
as double,winningBalance: null == winningBalance ? _self.winningBalance : winningBalance // ignore: cast_nullable_to_non_nullable
as double,followersCount: null == followersCount ? _self.followersCount : followersCount // ignore: cast_nullable_to_non_nullable
as int,followingCount: null == followingCount ? _self.followingCount : followingCount // ignore: cast_nullable_to_non_nullable
as int,contestsPlayed: null == contestsPlayed ? _self.contestsPlayed : contestsPlayed // ignore: cast_nullable_to_non_nullable
as int,contestsWon: null == contestsWon ? _self.contestsWon : contestsWon // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastLoginAt: freezed == lastLoginAt ? _self.lastLoginAt : lastLoginAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserEntity].
extension UserEntityPatterns on UserEntity {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserEntity() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserEntity value)  $default,){
final _that = this;
switch (_that) {
case _UserEntity():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserEntity value)?  $default,){
final _that = this;
switch (_that) {
case _UserEntity() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String? email,  String? phoneNumber,  String? displayName,  String? photoUrl,  String? bio,  String? selectedState,  bool isRestricted,  bool isPhoneVerified,  bool isEmailVerified,  double walletBalance,  double bonusBalance,  double winningBalance,  int followersCount,  int followingCount,  int contestsPlayed,  int contestsWon, @TimestampConverter()  DateTime? createdAt, @TimestampConverter()  DateTime? lastLoginAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserEntity() when $default != null:
return $default(_that.uid,_that.email,_that.phoneNumber,_that.displayName,_that.photoUrl,_that.bio,_that.selectedState,_that.isRestricted,_that.isPhoneVerified,_that.isEmailVerified,_that.walletBalance,_that.bonusBalance,_that.winningBalance,_that.followersCount,_that.followingCount,_that.contestsPlayed,_that.contestsWon,_that.createdAt,_that.lastLoginAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String? email,  String? phoneNumber,  String? displayName,  String? photoUrl,  String? bio,  String? selectedState,  bool isRestricted,  bool isPhoneVerified,  bool isEmailVerified,  double walletBalance,  double bonusBalance,  double winningBalance,  int followersCount,  int followingCount,  int contestsPlayed,  int contestsWon, @TimestampConverter()  DateTime? createdAt, @TimestampConverter()  DateTime? lastLoginAt)  $default,) {final _that = this;
switch (_that) {
case _UserEntity():
return $default(_that.uid,_that.email,_that.phoneNumber,_that.displayName,_that.photoUrl,_that.bio,_that.selectedState,_that.isRestricted,_that.isPhoneVerified,_that.isEmailVerified,_that.walletBalance,_that.bonusBalance,_that.winningBalance,_that.followersCount,_that.followingCount,_that.contestsPlayed,_that.contestsWon,_that.createdAt,_that.lastLoginAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String? email,  String? phoneNumber,  String? displayName,  String? photoUrl,  String? bio,  String? selectedState,  bool isRestricted,  bool isPhoneVerified,  bool isEmailVerified,  double walletBalance,  double bonusBalance,  double winningBalance,  int followersCount,  int followingCount,  int contestsPlayed,  int contestsWon, @TimestampConverter()  DateTime? createdAt, @TimestampConverter()  DateTime? lastLoginAt)?  $default,) {final _that = this;
switch (_that) {
case _UserEntity() when $default != null:
return $default(_that.uid,_that.email,_that.phoneNumber,_that.displayName,_that.photoUrl,_that.bio,_that.selectedState,_that.isRestricted,_that.isPhoneVerified,_that.isEmailVerified,_that.walletBalance,_that.bonusBalance,_that.winningBalance,_that.followersCount,_that.followingCount,_that.contestsPlayed,_that.contestsWon,_that.createdAt,_that.lastLoginAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserEntity implements UserEntity {
  const _UserEntity({required this.uid, this.email, this.phoneNumber, this.displayName, this.photoUrl, this.bio, this.selectedState, this.isRestricted = false, this.isPhoneVerified = false, this.isEmailVerified = false, this.walletBalance = 0, this.bonusBalance = 0, this.winningBalance = 0, this.followersCount = 0, this.followingCount = 0, this.contestsPlayed = 0, this.contestsWon = 0, @TimestampConverter() this.createdAt, @TimestampConverter() this.lastLoginAt});
  factory _UserEntity.fromJson(Map<String, dynamic> json) => _$UserEntityFromJson(json);

@override final  String uid;
@override final  String? email;
@override final  String? phoneNumber;
@override final  String? displayName;
@override final  String? photoUrl;
@override final  String? bio;
@override final  String? selectedState;
@override@JsonKey() final  bool isRestricted;
@override@JsonKey() final  bool isPhoneVerified;
@override@JsonKey() final  bool isEmailVerified;
@override@JsonKey() final  double walletBalance;
@override@JsonKey() final  double bonusBalance;
@override@JsonKey() final  double winningBalance;
@override@JsonKey() final  int followersCount;
@override@JsonKey() final  int followingCount;
@override@JsonKey() final  int contestsPlayed;
@override@JsonKey() final  int contestsWon;
@override@TimestampConverter() final  DateTime? createdAt;
@override@TimestampConverter() final  DateTime? lastLoginAt;

/// Create a copy of UserEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserEntityCopyWith<_UserEntity> get copyWith => __$UserEntityCopyWithImpl<_UserEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserEntity&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.email, email) || other.email == email)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.selectedState, selectedState) || other.selectedState == selectedState)&&(identical(other.isRestricted, isRestricted) || other.isRestricted == isRestricted)&&(identical(other.isPhoneVerified, isPhoneVerified) || other.isPhoneVerified == isPhoneVerified)&&(identical(other.isEmailVerified, isEmailVerified) || other.isEmailVerified == isEmailVerified)&&(identical(other.walletBalance, walletBalance) || other.walletBalance == walletBalance)&&(identical(other.bonusBalance, bonusBalance) || other.bonusBalance == bonusBalance)&&(identical(other.winningBalance, winningBalance) || other.winningBalance == winningBalance)&&(identical(other.followersCount, followersCount) || other.followersCount == followersCount)&&(identical(other.followingCount, followingCount) || other.followingCount == followingCount)&&(identical(other.contestsPlayed, contestsPlayed) || other.contestsPlayed == contestsPlayed)&&(identical(other.contestsWon, contestsWon) || other.contestsWon == contestsWon)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastLoginAt, lastLoginAt) || other.lastLoginAt == lastLoginAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,uid,email,phoneNumber,displayName,photoUrl,bio,selectedState,isRestricted,isPhoneVerified,isEmailVerified,walletBalance,bonusBalance,winningBalance,followersCount,followingCount,contestsPlayed,contestsWon,createdAt,lastLoginAt]);

@override
String toString() {
  return 'UserEntity(uid: $uid, email: $email, phoneNumber: $phoneNumber, displayName: $displayName, photoUrl: $photoUrl, bio: $bio, selectedState: $selectedState, isRestricted: $isRestricted, isPhoneVerified: $isPhoneVerified, isEmailVerified: $isEmailVerified, walletBalance: $walletBalance, bonusBalance: $bonusBalance, winningBalance: $winningBalance, followersCount: $followersCount, followingCount: $followingCount, contestsPlayed: $contestsPlayed, contestsWon: $contestsWon, createdAt: $createdAt, lastLoginAt: $lastLoginAt)';
}


}

/// @nodoc
abstract mixin class _$UserEntityCopyWith<$Res> implements $UserEntityCopyWith<$Res> {
  factory _$UserEntityCopyWith(_UserEntity value, $Res Function(_UserEntity) _then) = __$UserEntityCopyWithImpl;
@override @useResult
$Res call({
 String uid, String? email, String? phoneNumber, String? displayName, String? photoUrl, String? bio, String? selectedState, bool isRestricted, bool isPhoneVerified, bool isEmailVerified, double walletBalance, double bonusBalance, double winningBalance, int followersCount, int followingCount, int contestsPlayed, int contestsWon,@TimestampConverter() DateTime? createdAt,@TimestampConverter() DateTime? lastLoginAt
});




}
/// @nodoc
class __$UserEntityCopyWithImpl<$Res>
    implements _$UserEntityCopyWith<$Res> {
  __$UserEntityCopyWithImpl(this._self, this._then);

  final _UserEntity _self;
  final $Res Function(_UserEntity) _then;

/// Create a copy of UserEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? email = freezed,Object? phoneNumber = freezed,Object? displayName = freezed,Object? photoUrl = freezed,Object? bio = freezed,Object? selectedState = freezed,Object? isRestricted = null,Object? isPhoneVerified = null,Object? isEmailVerified = null,Object? walletBalance = null,Object? bonusBalance = null,Object? winningBalance = null,Object? followersCount = null,Object? followingCount = null,Object? contestsPlayed = null,Object? contestsWon = null,Object? createdAt = freezed,Object? lastLoginAt = freezed,}) {
  return _then(_UserEntity(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,selectedState: freezed == selectedState ? _self.selectedState : selectedState // ignore: cast_nullable_to_non_nullable
as String?,isRestricted: null == isRestricted ? _self.isRestricted : isRestricted // ignore: cast_nullable_to_non_nullable
as bool,isPhoneVerified: null == isPhoneVerified ? _self.isPhoneVerified : isPhoneVerified // ignore: cast_nullable_to_non_nullable
as bool,isEmailVerified: null == isEmailVerified ? _self.isEmailVerified : isEmailVerified // ignore: cast_nullable_to_non_nullable
as bool,walletBalance: null == walletBalance ? _self.walletBalance : walletBalance // ignore: cast_nullable_to_non_nullable
as double,bonusBalance: null == bonusBalance ? _self.bonusBalance : bonusBalance // ignore: cast_nullable_to_non_nullable
as double,winningBalance: null == winningBalance ? _self.winningBalance : winningBalance // ignore: cast_nullable_to_non_nullable
as double,followersCount: null == followersCount ? _self.followersCount : followersCount // ignore: cast_nullable_to_non_nullable
as int,followingCount: null == followingCount ? _self.followingCount : followingCount // ignore: cast_nullable_to_non_nullable
as int,contestsPlayed: null == contestsPlayed ? _self.contestsPlayed : contestsPlayed // ignore: cast_nullable_to_non_nullable
as int,contestsWon: null == contestsWon ? _self.contestsWon : contestsWon // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastLoginAt: freezed == lastLoginAt ? _self.lastLoginAt : lastLoginAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
