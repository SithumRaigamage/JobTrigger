// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'jenkins_build_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JenkinsBuildDto {

 int get number; String get url; String? get result;// SUCCESS | FAILURE | ABORTED | UNSTABLE | null (building)
 double get timestamp;// epoch ms
 double? get duration; double? get estimatedDuration; bool get building; String? get displayName;
/// Create a copy of JenkinsBuildDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JenkinsBuildDtoCopyWith<JenkinsBuildDto> get copyWith => _$JenkinsBuildDtoCopyWithImpl<JenkinsBuildDto>(this as JenkinsBuildDto, _$identity);

  /// Serializes this JenkinsBuildDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JenkinsBuildDto&&(identical(other.number, number) || other.number == number)&&(identical(other.url, url) || other.url == url)&&(identical(other.result, result) || other.result == result)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.estimatedDuration, estimatedDuration) || other.estimatedDuration == estimatedDuration)&&(identical(other.building, building) || other.building == building)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,url,result,timestamp,duration,estimatedDuration,building,displayName);

@override
String toString() {
  return 'JenkinsBuildDto(number: $number, url: $url, result: $result, timestamp: $timestamp, duration: $duration, estimatedDuration: $estimatedDuration, building: $building, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class $JenkinsBuildDtoCopyWith<$Res>  {
  factory $JenkinsBuildDtoCopyWith(JenkinsBuildDto value, $Res Function(JenkinsBuildDto) _then) = _$JenkinsBuildDtoCopyWithImpl;
@useResult
$Res call({
 int number, String url, String? result, double timestamp, double? duration, double? estimatedDuration, bool building, String? displayName
});




}
/// @nodoc
class _$JenkinsBuildDtoCopyWithImpl<$Res>
    implements $JenkinsBuildDtoCopyWith<$Res> {
  _$JenkinsBuildDtoCopyWithImpl(this._self, this._then);

  final JenkinsBuildDto _self;
  final $Res Function(JenkinsBuildDto) _then;

/// Create a copy of JenkinsBuildDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? number = null,Object? url = null,Object? result = freezed,Object? timestamp = null,Object? duration = freezed,Object? estimatedDuration = freezed,Object? building = null,Object? displayName = freezed,}) {
  return _then(_self.copyWith(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as double,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as double?,estimatedDuration: freezed == estimatedDuration ? _self.estimatedDuration : estimatedDuration // ignore: cast_nullable_to_non_nullable
as double?,building: null == building ? _self.building : building // ignore: cast_nullable_to_non_nullable
as bool,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [JenkinsBuildDto].
extension JenkinsBuildDtoPatterns on JenkinsBuildDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JenkinsBuildDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JenkinsBuildDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JenkinsBuildDto value)  $default,){
final _that = this;
switch (_that) {
case _JenkinsBuildDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JenkinsBuildDto value)?  $default,){
final _that = this;
switch (_that) {
case _JenkinsBuildDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int number,  String url,  String? result,  double timestamp,  double? duration,  double? estimatedDuration,  bool building,  String? displayName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JenkinsBuildDto() when $default != null:
return $default(_that.number,_that.url,_that.result,_that.timestamp,_that.duration,_that.estimatedDuration,_that.building,_that.displayName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int number,  String url,  String? result,  double timestamp,  double? duration,  double? estimatedDuration,  bool building,  String? displayName)  $default,) {final _that = this;
switch (_that) {
case _JenkinsBuildDto():
return $default(_that.number,_that.url,_that.result,_that.timestamp,_that.duration,_that.estimatedDuration,_that.building,_that.displayName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int number,  String url,  String? result,  double timestamp,  double? duration,  double? estimatedDuration,  bool building,  String? displayName)?  $default,) {final _that = this;
switch (_that) {
case _JenkinsBuildDto() when $default != null:
return $default(_that.number,_that.url,_that.result,_that.timestamp,_that.duration,_that.estimatedDuration,_that.building,_that.displayName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JenkinsBuildDto implements JenkinsBuildDto {
  const _JenkinsBuildDto({required this.number, required this.url, this.result, required this.timestamp, this.duration, this.estimatedDuration, this.building = false, this.displayName});
  factory _JenkinsBuildDto.fromJson(Map<String, dynamic> json) => _$JenkinsBuildDtoFromJson(json);

@override final  int number;
@override final  String url;
@override final  String? result;
// SUCCESS | FAILURE | ABORTED | UNSTABLE | null (building)
@override final  double timestamp;
// epoch ms
@override final  double? duration;
@override final  double? estimatedDuration;
@override@JsonKey() final  bool building;
@override final  String? displayName;

/// Create a copy of JenkinsBuildDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JenkinsBuildDtoCopyWith<_JenkinsBuildDto> get copyWith => __$JenkinsBuildDtoCopyWithImpl<_JenkinsBuildDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JenkinsBuildDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JenkinsBuildDto&&(identical(other.number, number) || other.number == number)&&(identical(other.url, url) || other.url == url)&&(identical(other.result, result) || other.result == result)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.estimatedDuration, estimatedDuration) || other.estimatedDuration == estimatedDuration)&&(identical(other.building, building) || other.building == building)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,url,result,timestamp,duration,estimatedDuration,building,displayName);

@override
String toString() {
  return 'JenkinsBuildDto(number: $number, url: $url, result: $result, timestamp: $timestamp, duration: $duration, estimatedDuration: $estimatedDuration, building: $building, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class _$JenkinsBuildDtoCopyWith<$Res> implements $JenkinsBuildDtoCopyWith<$Res> {
  factory _$JenkinsBuildDtoCopyWith(_JenkinsBuildDto value, $Res Function(_JenkinsBuildDto) _then) = __$JenkinsBuildDtoCopyWithImpl;
@override @useResult
$Res call({
 int number, String url, String? result, double timestamp, double? duration, double? estimatedDuration, bool building, String? displayName
});




}
/// @nodoc
class __$JenkinsBuildDtoCopyWithImpl<$Res>
    implements _$JenkinsBuildDtoCopyWith<$Res> {
  __$JenkinsBuildDtoCopyWithImpl(this._self, this._then);

  final _JenkinsBuildDto _self;
  final $Res Function(_JenkinsBuildDto) _then;

/// Create a copy of JenkinsBuildDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? number = null,Object? url = null,Object? result = freezed,Object? timestamp = null,Object? duration = freezed,Object? estimatedDuration = freezed,Object? building = null,Object? displayName = freezed,}) {
  return _then(_JenkinsBuildDto(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as double,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as double?,estimatedDuration: freezed == estimatedDuration ? _self.estimatedDuration : estimatedDuration // ignore: cast_nullable_to_non_nullable
as double?,building: null == building ? _self.building : building // ignore: cast_nullable_to_non_nullable
as bool,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
