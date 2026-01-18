// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contest_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ContestModel {

 String get id; int get matchId; double get entryFee; int get totalSpots; int get filledSpots; double get prizePool; String get category;// e.g., "Mega Contest", "Head 2 Head"
 bool get isGuaranteed; bool get isFlexible;// List of payout tiers: [{'rankStart': 1, 'rankEnd': 1, 'amount': 1000}, ...]
 List<Map<String, dynamic>> get winningBreakdown; DateTime get createdAt;
/// Create a copy of ContestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContestModelCopyWith<ContestModel> get copyWith => _$ContestModelCopyWithImpl<ContestModel>(this as ContestModel, _$identity);

  /// Serializes this ContestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContestModel&&(identical(other.id, id) || other.id == id)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.entryFee, entryFee) || other.entryFee == entryFee)&&(identical(other.totalSpots, totalSpots) || other.totalSpots == totalSpots)&&(identical(other.filledSpots, filledSpots) || other.filledSpots == filledSpots)&&(identical(other.prizePool, prizePool) || other.prizePool == prizePool)&&(identical(other.category, category) || other.category == category)&&(identical(other.isGuaranteed, isGuaranteed) || other.isGuaranteed == isGuaranteed)&&(identical(other.isFlexible, isFlexible) || other.isFlexible == isFlexible)&&const DeepCollectionEquality().equals(other.winningBreakdown, winningBreakdown)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,matchId,entryFee,totalSpots,filledSpots,prizePool,category,isGuaranteed,isFlexible,const DeepCollectionEquality().hash(winningBreakdown),createdAt);

@override
String toString() {
  return 'ContestModel(id: $id, matchId: $matchId, entryFee: $entryFee, totalSpots: $totalSpots, filledSpots: $filledSpots, prizePool: $prizePool, category: $category, isGuaranteed: $isGuaranteed, isFlexible: $isFlexible, winningBreakdown: $winningBreakdown, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ContestModelCopyWith<$Res>  {
  factory $ContestModelCopyWith(ContestModel value, $Res Function(ContestModel) _then) = _$ContestModelCopyWithImpl;
@useResult
$Res call({
 String id, int matchId, double entryFee, int totalSpots, int filledSpots, double prizePool, String category, bool isGuaranteed, bool isFlexible, List<Map<String, dynamic>> winningBreakdown, DateTime createdAt
});




}
/// @nodoc
class _$ContestModelCopyWithImpl<$Res>
    implements $ContestModelCopyWith<$Res> {
  _$ContestModelCopyWithImpl(this._self, this._then);

  final ContestModel _self;
  final $Res Function(ContestModel) _then;

/// Create a copy of ContestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? matchId = null,Object? entryFee = null,Object? totalSpots = null,Object? filledSpots = null,Object? prizePool = null,Object? category = null,Object? isGuaranteed = null,Object? isFlexible = null,Object? winningBreakdown = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as int,entryFee: null == entryFee ? _self.entryFee : entryFee // ignore: cast_nullable_to_non_nullable
as double,totalSpots: null == totalSpots ? _self.totalSpots : totalSpots // ignore: cast_nullable_to_non_nullable
as int,filledSpots: null == filledSpots ? _self.filledSpots : filledSpots // ignore: cast_nullable_to_non_nullable
as int,prizePool: null == prizePool ? _self.prizePool : prizePool // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,isGuaranteed: null == isGuaranteed ? _self.isGuaranteed : isGuaranteed // ignore: cast_nullable_to_non_nullable
as bool,isFlexible: null == isFlexible ? _self.isFlexible : isFlexible // ignore: cast_nullable_to_non_nullable
as bool,winningBreakdown: null == winningBreakdown ? _self.winningBreakdown : winningBreakdown // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ContestModel].
extension ContestModelPatterns on ContestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContestModel value)  $default,){
final _that = this;
switch (_that) {
case _ContestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContestModel value)?  $default,){
final _that = this;
switch (_that) {
case _ContestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int matchId,  double entryFee,  int totalSpots,  int filledSpots,  double prizePool,  String category,  bool isGuaranteed,  bool isFlexible,  List<Map<String, dynamic>> winningBreakdown,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContestModel() when $default != null:
return $default(_that.id,_that.matchId,_that.entryFee,_that.totalSpots,_that.filledSpots,_that.prizePool,_that.category,_that.isGuaranteed,_that.isFlexible,_that.winningBreakdown,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int matchId,  double entryFee,  int totalSpots,  int filledSpots,  double prizePool,  String category,  bool isGuaranteed,  bool isFlexible,  List<Map<String, dynamic>> winningBreakdown,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _ContestModel():
return $default(_that.id,_that.matchId,_that.entryFee,_that.totalSpots,_that.filledSpots,_that.prizePool,_that.category,_that.isGuaranteed,_that.isFlexible,_that.winningBreakdown,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int matchId,  double entryFee,  int totalSpots,  int filledSpots,  double prizePool,  String category,  bool isGuaranteed,  bool isFlexible,  List<Map<String, dynamic>> winningBreakdown,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ContestModel() when $default != null:
return $default(_that.id,_that.matchId,_that.entryFee,_that.totalSpots,_that.filledSpots,_that.prizePool,_that.category,_that.isGuaranteed,_that.isFlexible,_that.winningBreakdown,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ContestModel implements ContestModel {
  const _ContestModel({required this.id, required this.matchId, required this.entryFee, required this.totalSpots, required this.filledSpots, required this.prizePool, required this.category, this.isGuaranteed = false, this.isFlexible = false, final  List<Map<String, dynamic>> winningBreakdown = const [], required this.createdAt}): _winningBreakdown = winningBreakdown;
  factory _ContestModel.fromJson(Map<String, dynamic> json) => _$ContestModelFromJson(json);

@override final  String id;
@override final  int matchId;
@override final  double entryFee;
@override final  int totalSpots;
@override final  int filledSpots;
@override final  double prizePool;
@override final  String category;
// e.g., "Mega Contest", "Head 2 Head"
@override@JsonKey() final  bool isGuaranteed;
@override@JsonKey() final  bool isFlexible;
// List of payout tiers: [{'rankStart': 1, 'rankEnd': 1, 'amount': 1000}, ...]
 final  List<Map<String, dynamic>> _winningBreakdown;
// List of payout tiers: [{'rankStart': 1, 'rankEnd': 1, 'amount': 1000}, ...]
@override@JsonKey() List<Map<String, dynamic>> get winningBreakdown {
  if (_winningBreakdown is EqualUnmodifiableListView) return _winningBreakdown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_winningBreakdown);
}

@override final  DateTime createdAt;

/// Create a copy of ContestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContestModelCopyWith<_ContestModel> get copyWith => __$ContestModelCopyWithImpl<_ContestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContestModel&&(identical(other.id, id) || other.id == id)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.entryFee, entryFee) || other.entryFee == entryFee)&&(identical(other.totalSpots, totalSpots) || other.totalSpots == totalSpots)&&(identical(other.filledSpots, filledSpots) || other.filledSpots == filledSpots)&&(identical(other.prizePool, prizePool) || other.prizePool == prizePool)&&(identical(other.category, category) || other.category == category)&&(identical(other.isGuaranteed, isGuaranteed) || other.isGuaranteed == isGuaranteed)&&(identical(other.isFlexible, isFlexible) || other.isFlexible == isFlexible)&&const DeepCollectionEquality().equals(other._winningBreakdown, _winningBreakdown)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,matchId,entryFee,totalSpots,filledSpots,prizePool,category,isGuaranteed,isFlexible,const DeepCollectionEquality().hash(_winningBreakdown),createdAt);

@override
String toString() {
  return 'ContestModel(id: $id, matchId: $matchId, entryFee: $entryFee, totalSpots: $totalSpots, filledSpots: $filledSpots, prizePool: $prizePool, category: $category, isGuaranteed: $isGuaranteed, isFlexible: $isFlexible, winningBreakdown: $winningBreakdown, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ContestModelCopyWith<$Res> implements $ContestModelCopyWith<$Res> {
  factory _$ContestModelCopyWith(_ContestModel value, $Res Function(_ContestModel) _then) = __$ContestModelCopyWithImpl;
@override @useResult
$Res call({
 String id, int matchId, double entryFee, int totalSpots, int filledSpots, double prizePool, String category, bool isGuaranteed, bool isFlexible, List<Map<String, dynamic>> winningBreakdown, DateTime createdAt
});




}
/// @nodoc
class __$ContestModelCopyWithImpl<$Res>
    implements _$ContestModelCopyWith<$Res> {
  __$ContestModelCopyWithImpl(this._self, this._then);

  final _ContestModel _self;
  final $Res Function(_ContestModel) _then;

/// Create a copy of ContestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? matchId = null,Object? entryFee = null,Object? totalSpots = null,Object? filledSpots = null,Object? prizePool = null,Object? category = null,Object? isGuaranteed = null,Object? isFlexible = null,Object? winningBreakdown = null,Object? createdAt = null,}) {
  return _then(_ContestModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as int,entryFee: null == entryFee ? _self.entryFee : entryFee // ignore: cast_nullable_to_non_nullable
as double,totalSpots: null == totalSpots ? _self.totalSpots : totalSpots // ignore: cast_nullable_to_non_nullable
as int,filledSpots: null == filledSpots ? _self.filledSpots : filledSpots // ignore: cast_nullable_to_non_nullable
as int,prizePool: null == prizePool ? _self.prizePool : prizePool // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,isGuaranteed: null == isGuaranteed ? _self.isGuaranteed : isGuaranteed // ignore: cast_nullable_to_non_nullable
as bool,isFlexible: null == isFlexible ? _self.isFlexible : isFlexible // ignore: cast_nullable_to_non_nullable
as bool,winningBreakdown: null == winningBreakdown ? _self._winningBreakdown : winningBreakdown // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
