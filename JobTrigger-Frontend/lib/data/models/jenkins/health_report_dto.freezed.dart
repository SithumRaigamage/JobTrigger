// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'health_report_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HealthReportDto {

 String? get description; String? get iconClassName; int? get score;
/// Create a copy of HealthReportDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HealthReportDtoCopyWith<HealthReportDto> get copyWith => _$HealthReportDtoCopyWithImpl<HealthReportDto>(this as HealthReportDto, _$identity);

  /// Serializes this HealthReportDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HealthReportDto&&(identical(other.description, description) || other.description == description)&&(identical(other.iconClassName, iconClassName) || other.iconClassName == iconClassName)&&(identical(other.score, score) || other.score == score));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,description,iconClassName,score);

@override
String toString() {
  return 'HealthReportDto(description: $description, iconClassName: $iconClassName, score: $score)';
}


}

/// @nodoc
abstract mixin class $HealthReportDtoCopyWith<$Res>  {
  factory $HealthReportDtoCopyWith(HealthReportDto value, $Res Function(HealthReportDto) _then) = _$HealthReportDtoCopyWithImpl;
@useResult
$Res call({
 String? description, String? iconClassName, int? score
});




}
/// @nodoc
class _$HealthReportDtoCopyWithImpl<$Res>
    implements $HealthReportDtoCopyWith<$Res> {
  _$HealthReportDtoCopyWithImpl(this._self, this._then);

  final HealthReportDto _self;
  final $Res Function(HealthReportDto) _then;

/// Create a copy of HealthReportDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? description = freezed,Object? iconClassName = freezed,Object? score = freezed,}) {
  return _then(_self.copyWith(
description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,iconClassName: freezed == iconClassName ? _self.iconClassName : iconClassName // ignore: cast_nullable_to_non_nullable
as String?,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [HealthReportDto].
extension HealthReportDtoPatterns on HealthReportDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HealthReportDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HealthReportDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HealthReportDto value)  $default,){
final _that = this;
switch (_that) {
case _HealthReportDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HealthReportDto value)?  $default,){
final _that = this;
switch (_that) {
case _HealthReportDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? description,  String? iconClassName,  int? score)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HealthReportDto() when $default != null:
return $default(_that.description,_that.iconClassName,_that.score);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? description,  String? iconClassName,  int? score)  $default,) {final _that = this;
switch (_that) {
case _HealthReportDto():
return $default(_that.description,_that.iconClassName,_that.score);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? description,  String? iconClassName,  int? score)?  $default,) {final _that = this;
switch (_that) {
case _HealthReportDto() when $default != null:
return $default(_that.description,_that.iconClassName,_that.score);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HealthReportDto implements HealthReportDto {
  const _HealthReportDto({this.description, this.iconClassName, this.score});
  factory _HealthReportDto.fromJson(Map<String, dynamic> json) => _$HealthReportDtoFromJson(json);

@override final  String? description;
@override final  String? iconClassName;
@override final  int? score;

/// Create a copy of HealthReportDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HealthReportDtoCopyWith<_HealthReportDto> get copyWith => __$HealthReportDtoCopyWithImpl<_HealthReportDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HealthReportDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HealthReportDto&&(identical(other.description, description) || other.description == description)&&(identical(other.iconClassName, iconClassName) || other.iconClassName == iconClassName)&&(identical(other.score, score) || other.score == score));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,description,iconClassName,score);

@override
String toString() {
  return 'HealthReportDto(description: $description, iconClassName: $iconClassName, score: $score)';
}


}

/// @nodoc
abstract mixin class _$HealthReportDtoCopyWith<$Res> implements $HealthReportDtoCopyWith<$Res> {
  factory _$HealthReportDtoCopyWith(_HealthReportDto value, $Res Function(_HealthReportDto) _then) = __$HealthReportDtoCopyWithImpl;
@override @useResult
$Res call({
 String? description, String? iconClassName, int? score
});




}
/// @nodoc
class __$HealthReportDtoCopyWithImpl<$Res>
    implements _$HealthReportDtoCopyWith<$Res> {
  __$HealthReportDtoCopyWithImpl(this._self, this._then);

  final _HealthReportDto _self;
  final $Res Function(_HealthReportDto) _then;

/// Create a copy of HealthReportDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? description = freezed,Object? iconClassName = freezed,Object? score = freezed,}) {
  return _then(_HealthReportDto(
description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,iconClassName: freezed == iconClassName ? _self.iconClassName : iconClassName // ignore: cast_nullable_to_non_nullable
as String?,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
