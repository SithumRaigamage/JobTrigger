// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sonarqube_project_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SonarQubeProjectDto {

 String get key; String get name; String? get lastAnalysisDate;
/// Create a copy of SonarQubeProjectDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SonarQubeProjectDtoCopyWith<SonarQubeProjectDto> get copyWith => _$SonarQubeProjectDtoCopyWithImpl<SonarQubeProjectDto>(this as SonarQubeProjectDto, _$identity);

  /// Serializes this SonarQubeProjectDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SonarQubeProjectDto&&(identical(other.key, key) || other.key == key)&&(identical(other.name, name) || other.name == name)&&(identical(other.lastAnalysisDate, lastAnalysisDate) || other.lastAnalysisDate == lastAnalysisDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,name,lastAnalysisDate);

@override
String toString() {
  return 'SonarQubeProjectDto(key: $key, name: $name, lastAnalysisDate: $lastAnalysisDate)';
}


}

/// @nodoc
abstract mixin class $SonarQubeProjectDtoCopyWith<$Res>  {
  factory $SonarQubeProjectDtoCopyWith(SonarQubeProjectDto value, $Res Function(SonarQubeProjectDto) _then) = _$SonarQubeProjectDtoCopyWithImpl;
@useResult
$Res call({
 String key, String name, String? lastAnalysisDate
});




}
/// @nodoc
class _$SonarQubeProjectDtoCopyWithImpl<$Res>
    implements $SonarQubeProjectDtoCopyWith<$Res> {
  _$SonarQubeProjectDtoCopyWithImpl(this._self, this._then);

  final SonarQubeProjectDto _self;
  final $Res Function(SonarQubeProjectDto) _then;

/// Create a copy of SonarQubeProjectDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? name = null,Object? lastAnalysisDate = freezed,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,lastAnalysisDate: freezed == lastAnalysisDate ? _self.lastAnalysisDate : lastAnalysisDate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SonarQubeProjectDto].
extension SonarQubeProjectDtoPatterns on SonarQubeProjectDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SonarQubeProjectDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SonarQubeProjectDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SonarQubeProjectDto value)  $default,){
final _that = this;
switch (_that) {
case _SonarQubeProjectDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SonarQubeProjectDto value)?  $default,){
final _that = this;
switch (_that) {
case _SonarQubeProjectDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String name,  String? lastAnalysisDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SonarQubeProjectDto() when $default != null:
return $default(_that.key,_that.name,_that.lastAnalysisDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String name,  String? lastAnalysisDate)  $default,) {final _that = this;
switch (_that) {
case _SonarQubeProjectDto():
return $default(_that.key,_that.name,_that.lastAnalysisDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String name,  String? lastAnalysisDate)?  $default,) {final _that = this;
switch (_that) {
case _SonarQubeProjectDto() when $default != null:
return $default(_that.key,_that.name,_that.lastAnalysisDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SonarQubeProjectDto implements SonarQubeProjectDto {
  const _SonarQubeProjectDto({required this.key, this.name = '', this.lastAnalysisDate});
  factory _SonarQubeProjectDto.fromJson(Map<String, dynamic> json) => _$SonarQubeProjectDtoFromJson(json);

@override final  String key;
@override@JsonKey() final  String name;
@override final  String? lastAnalysisDate;

/// Create a copy of SonarQubeProjectDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SonarQubeProjectDtoCopyWith<_SonarQubeProjectDto> get copyWith => __$SonarQubeProjectDtoCopyWithImpl<_SonarQubeProjectDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SonarQubeProjectDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SonarQubeProjectDto&&(identical(other.key, key) || other.key == key)&&(identical(other.name, name) || other.name == name)&&(identical(other.lastAnalysisDate, lastAnalysisDate) || other.lastAnalysisDate == lastAnalysisDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,name,lastAnalysisDate);

@override
String toString() {
  return 'SonarQubeProjectDto(key: $key, name: $name, lastAnalysisDate: $lastAnalysisDate)';
}


}

/// @nodoc
abstract mixin class _$SonarQubeProjectDtoCopyWith<$Res> implements $SonarQubeProjectDtoCopyWith<$Res> {
  factory _$SonarQubeProjectDtoCopyWith(_SonarQubeProjectDto value, $Res Function(_SonarQubeProjectDto) _then) = __$SonarQubeProjectDtoCopyWithImpl;
@override @useResult
$Res call({
 String key, String name, String? lastAnalysisDate
});




}
/// @nodoc
class __$SonarQubeProjectDtoCopyWithImpl<$Res>
    implements _$SonarQubeProjectDtoCopyWith<$Res> {
  __$SonarQubeProjectDtoCopyWithImpl(this._self, this._then);

  final _SonarQubeProjectDto _self;
  final $Res Function(_SonarQubeProjectDto) _then;

/// Create a copy of SonarQubeProjectDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? name = null,Object? lastAnalysisDate = freezed,}) {
  return _then(_SonarQubeProjectDto(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,lastAnalysisDate: freezed == lastAnalysisDate ? _self.lastAnalysisDate : lastAnalysisDate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
