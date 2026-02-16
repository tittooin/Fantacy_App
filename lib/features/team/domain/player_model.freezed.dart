// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlayerModel {

 String get id; String get name; String? get teamShortName;// e.g., "CSK" - Nullable to handle legacy data
 String get role;// "WK", "BAT", "AR", "BOWL"
 double get credits;// e.g., 9.0
 String get imageUrl;// URL or asset path
 double get points;// Last match points or average
 double get fantasyRating;// NEW: Selection Helper (0-100)
 bool get isPlaying;// For lineup announcement
 String? get teamId;
/// Create a copy of PlayerModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerModelCopyWith<PlayerModel> get copyWith => _$PlayerModelCopyWithImpl<PlayerModel>(this as PlayerModel, _$identity);

  /// Serializes this PlayerModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.teamShortName, teamShortName) || other.teamShortName == teamShortName)&&(identical(other.role, role) || other.role == role)&&(identical(other.credits, credits) || other.credits == credits)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.points, points) || other.points == points)&&(identical(other.fantasyRating, fantasyRating) || other.fantasyRating == fantasyRating)&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying)&&(identical(other.teamId, teamId) || other.teamId == teamId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,teamShortName,role,credits,imageUrl,points,fantasyRating,isPlaying,teamId);

@override
String toString() {
  return 'PlayerModel(id: $id, name: $name, teamShortName: $teamShortName, role: $role, credits: $credits, imageUrl: $imageUrl, points: $points, fantasyRating: $fantasyRating, isPlaying: $isPlaying, teamId: $teamId)';
}


}

/// @nodoc
abstract mixin class $PlayerModelCopyWith<$Res>  {
  factory $PlayerModelCopyWith(PlayerModel value, $Res Function(PlayerModel) _then) = _$PlayerModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? teamShortName, String role, double credits, String imageUrl, double points, double fantasyRating, bool isPlaying, String? teamId
});




}
/// @nodoc
class _$PlayerModelCopyWithImpl<$Res>
    implements $PlayerModelCopyWith<$Res> {
  _$PlayerModelCopyWithImpl(this._self, this._then);

  final PlayerModel _self;
  final $Res Function(PlayerModel) _then;

/// Create a copy of PlayerModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? teamShortName = freezed,Object? role = null,Object? credits = null,Object? imageUrl = null,Object? points = null,Object? fantasyRating = null,Object? isPlaying = null,Object? teamId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,teamShortName: freezed == teamShortName ? _self.teamShortName : teamShortName // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,credits: null == credits ? _self.credits : credits // ignore: cast_nullable_to_non_nullable
as double,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as double,fantasyRating: null == fantasyRating ? _self.fantasyRating : fantasyRating // ignore: cast_nullable_to_non_nullable
as double,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,teamId: freezed == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerModel].
extension PlayerModelPatterns on PlayerModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerModel value)  $default,){
final _that = this;
switch (_that) {
case _PlayerModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerModel value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? teamShortName,  String role,  double credits,  String imageUrl,  double points,  double fantasyRating,  bool isPlaying,  String? teamId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerModel() when $default != null:
return $default(_that.id,_that.name,_that.teamShortName,_that.role,_that.credits,_that.imageUrl,_that.points,_that.fantasyRating,_that.isPlaying,_that.teamId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? teamShortName,  String role,  double credits,  String imageUrl,  double points,  double fantasyRating,  bool isPlaying,  String? teamId)  $default,) {final _that = this;
switch (_that) {
case _PlayerModel():
return $default(_that.id,_that.name,_that.teamShortName,_that.role,_that.credits,_that.imageUrl,_that.points,_that.fantasyRating,_that.isPlaying,_that.teamId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? teamShortName,  String role,  double credits,  String imageUrl,  double points,  double fantasyRating,  bool isPlaying,  String? teamId)?  $default,) {final _that = this;
switch (_that) {
case _PlayerModel() when $default != null:
return $default(_that.id,_that.name,_that.teamShortName,_that.role,_that.credits,_that.imageUrl,_that.points,_that.fantasyRating,_that.isPlaying,_that.teamId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerModel implements PlayerModel {
  const _PlayerModel({required this.id, required this.name, this.teamShortName, required this.role, required this.credits, required this.imageUrl, this.points = 0.0, this.fantasyRating = 0.0, this.isPlaying = false, this.teamId});
  factory _PlayerModel.fromJson(Map<String, dynamic> json) => _$PlayerModelFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? teamShortName;
// e.g., "CSK" - Nullable to handle legacy data
@override final  String role;
// "WK", "BAT", "AR", "BOWL"
@override final  double credits;
// e.g., 9.0
@override final  String imageUrl;
// URL or asset path
@override@JsonKey() final  double points;
// Last match points or average
@override@JsonKey() final  double fantasyRating;
// NEW: Selection Helper (0-100)
@override@JsonKey() final  bool isPlaying;
// For lineup announcement
@override final  String? teamId;

/// Create a copy of PlayerModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerModelCopyWith<_PlayerModel> get copyWith => __$PlayerModelCopyWithImpl<_PlayerModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.teamShortName, teamShortName) || other.teamShortName == teamShortName)&&(identical(other.role, role) || other.role == role)&&(identical(other.credits, credits) || other.credits == credits)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.points, points) || other.points == points)&&(identical(other.fantasyRating, fantasyRating) || other.fantasyRating == fantasyRating)&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying)&&(identical(other.teamId, teamId) || other.teamId == teamId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,teamShortName,role,credits,imageUrl,points,fantasyRating,isPlaying,teamId);

@override
String toString() {
  return 'PlayerModel(id: $id, name: $name, teamShortName: $teamShortName, role: $role, credits: $credits, imageUrl: $imageUrl, points: $points, fantasyRating: $fantasyRating, isPlaying: $isPlaying, teamId: $teamId)';
}


}

/// @nodoc
abstract mixin class _$PlayerModelCopyWith<$Res> implements $PlayerModelCopyWith<$Res> {
  factory _$PlayerModelCopyWith(_PlayerModel value, $Res Function(_PlayerModel) _then) = __$PlayerModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? teamShortName, String role, double credits, String imageUrl, double points, double fantasyRating, bool isPlaying, String? teamId
});




}
/// @nodoc
class __$PlayerModelCopyWithImpl<$Res>
    implements _$PlayerModelCopyWith<$Res> {
  __$PlayerModelCopyWithImpl(this._self, this._then);

  final _PlayerModel _self;
  final $Res Function(_PlayerModel) _then;

/// Create a copy of PlayerModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? teamShortName = freezed,Object? role = null,Object? credits = null,Object? imageUrl = null,Object? points = null,Object? fantasyRating = null,Object? isPlaying = null,Object? teamId = freezed,}) {
  return _then(_PlayerModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,teamShortName: freezed == teamShortName ? _self.teamShortName : teamShortName // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,credits: null == credits ? _self.credits : credits // ignore: cast_nullable_to_non_nullable
as double,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as double,fantasyRating: null == fantasyRating ? _self.fantasyRating : fantasyRating // ignore: cast_nullable_to_non_nullable
as double,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,teamId: freezed == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
