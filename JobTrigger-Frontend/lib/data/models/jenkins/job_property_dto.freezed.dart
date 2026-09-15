// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job_property_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JobPropertyDto {

 List<ParameterDefinitionDto>? get parameterDefinitions;
/// Create a copy of JobPropertyDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JobPropertyDtoCopyWith<JobPropertyDto> get copyWith => _$JobPropertyDtoCopyWithImpl<JobPropertyDto>(this as JobPropertyDto, _$identity);

  /// Serializes this JobPropertyDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JobPropertyDto&&const DeepCollectionEquality().equals(other.parameterDefinitions, parameterDefinitions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(parameterDefinitions));

@override
String toString() {
  return 'JobPropertyDto(parameterDefinitions: $parameterDefinitions)';
}


}

/// @nodoc
abstract mixin class $JobPropertyDtoCopyWith<$Res>  {
  factory $JobPropertyDtoCopyWith(JobPropertyDto value, $Res Function(JobPropertyDto) _then) = _$JobPropertyDtoCopyWithImpl;
@useResult
$Res call({
 List<ParameterDefinitionDto>? parameterDefinitions
});




}
/// @nodoc
class _$JobPropertyDtoCopyWithImpl<$Res>
    implements $JobPropertyDtoCopyWith<$Res> {
  _$JobPropertyDtoCopyWithImpl(this._self, this._then);

  final JobPropertyDto _self;
  final $Res Function(JobPropertyDto) _then;

/// Create a copy of JobPropertyDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? parameterDefinitions = freezed,}) {
  return _then(_self.copyWith(
parameterDefinitions: freezed == parameterDefinitions ? _self.parameterDefinitions : parameterDefinitions // ignore: cast_nullable_to_non_nullable
as List<ParameterDefinitionDto>?,
  ));
}

}


/// Adds pattern-matching-related methods to [JobPropertyDto].
extension JobPropertyDtoPatterns on JobPropertyDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JobPropertyDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JobPropertyDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JobPropertyDto value)  $default,){
final _that = this;
switch (_that) {
case _JobPropertyDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JobPropertyDto value)?  $default,){
final _that = this;
switch (_that) {
case _JobPropertyDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ParameterDefinitionDto>? parameterDefinitions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JobPropertyDto() when $default != null:
return $default(_that.parameterDefinitions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ParameterDefinitionDto>? parameterDefinitions)  $default,) {final _that = this;
switch (_that) {
case _JobPropertyDto():
return $default(_that.parameterDefinitions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ParameterDefinitionDto>? parameterDefinitions)?  $default,) {final _that = this;
switch (_that) {
case _JobPropertyDto() when $default != null:
return $default(_that.parameterDefinitions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JobPropertyDto implements JobPropertyDto {
  const _JobPropertyDto({final  List<ParameterDefinitionDto>? parameterDefinitions}): _parameterDefinitions = parameterDefinitions;
  factory _JobPropertyDto.fromJson(Map<String, dynamic> json) => _$JobPropertyDtoFromJson(json);

 final  List<ParameterDefinitionDto>? _parameterDefinitions;
@override List<ParameterDefinitionDto>? get parameterDefinitions {
  final value = _parameterDefinitions;
  if (value == null) return null;
  if (_parameterDefinitions is EqualUnmodifiableListView) return _parameterDefinitions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of JobPropertyDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JobPropertyDtoCopyWith<_JobPropertyDto> get copyWith => __$JobPropertyDtoCopyWithImpl<_JobPropertyDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JobPropertyDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JobPropertyDto&&const DeepCollectionEquality().equals(other._parameterDefinitions, _parameterDefinitions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_parameterDefinitions));

@override
String toString() {
  return 'JobPropertyDto(parameterDefinitions: $parameterDefinitions)';
}


}

/// @nodoc
abstract mixin class _$JobPropertyDtoCopyWith<$Res> implements $JobPropertyDtoCopyWith<$Res> {
  factory _$JobPropertyDtoCopyWith(_JobPropertyDto value, $Res Function(_JobPropertyDto) _then) = __$JobPropertyDtoCopyWithImpl;
@override @useResult
$Res call({
 List<ParameterDefinitionDto>? parameterDefinitions
});




}
/// @nodoc
class __$JobPropertyDtoCopyWithImpl<$Res>
    implements _$JobPropertyDtoCopyWith<$Res> {
  __$JobPropertyDtoCopyWithImpl(this._self, this._then);

  final _JobPropertyDto _self;
  final $Res Function(_JobPropertyDto) _then;

/// Create a copy of JobPropertyDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? parameterDefinitions = freezed,}) {
  return _then(_JobPropertyDto(
parameterDefinitions: freezed == parameterDefinitions ? _self._parameterDefinitions : parameterDefinitions // ignore: cast_nullable_to_non_nullable
as List<ParameterDefinitionDto>?,
  ));
}


}

// dart format on
