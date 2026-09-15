// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pipeline_stage_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PipelineDescribeDto {

 List<PipelineStageDto> get stages;
/// Create a copy of PipelineDescribeDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PipelineDescribeDtoCopyWith<PipelineDescribeDto> get copyWith => _$PipelineDescribeDtoCopyWithImpl<PipelineDescribeDto>(this as PipelineDescribeDto, _$identity);

  /// Serializes this PipelineDescribeDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PipelineDescribeDto&&const DeepCollectionEquality().equals(other.stages, stages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(stages));

@override
String toString() {
  return 'PipelineDescribeDto(stages: $stages)';
}


}

/// @nodoc
abstract mixin class $PipelineDescribeDtoCopyWith<$Res>  {
  factory $PipelineDescribeDtoCopyWith(PipelineDescribeDto value, $Res Function(PipelineDescribeDto) _then) = _$PipelineDescribeDtoCopyWithImpl;
@useResult
$Res call({
 List<PipelineStageDto> stages
});




}
/// @nodoc
class _$PipelineDescribeDtoCopyWithImpl<$Res>
    implements $PipelineDescribeDtoCopyWith<$Res> {
  _$PipelineDescribeDtoCopyWithImpl(this._self, this._then);

  final PipelineDescribeDto _self;
  final $Res Function(PipelineDescribeDto) _then;

/// Create a copy of PipelineDescribeDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stages = null,}) {
  return _then(_self.copyWith(
stages: null == stages ? _self.stages : stages // ignore: cast_nullable_to_non_nullable
as List<PipelineStageDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [PipelineDescribeDto].
extension PipelineDescribeDtoPatterns on PipelineDescribeDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PipelineDescribeDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PipelineDescribeDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PipelineDescribeDto value)  $default,){
final _that = this;
switch (_that) {
case _PipelineDescribeDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PipelineDescribeDto value)?  $default,){
final _that = this;
switch (_that) {
case _PipelineDescribeDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PipelineStageDto> stages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PipelineDescribeDto() when $default != null:
return $default(_that.stages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PipelineStageDto> stages)  $default,) {final _that = this;
switch (_that) {
case _PipelineDescribeDto():
return $default(_that.stages);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PipelineStageDto> stages)?  $default,) {final _that = this;
switch (_that) {
case _PipelineDescribeDto() when $default != null:
return $default(_that.stages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PipelineDescribeDto implements PipelineDescribeDto {
  const _PipelineDescribeDto({final  List<PipelineStageDto> stages = const <PipelineStageDto>[]}): _stages = stages;
  factory _PipelineDescribeDto.fromJson(Map<String, dynamic> json) => _$PipelineDescribeDtoFromJson(json);

 final  List<PipelineStageDto> _stages;
@override@JsonKey() List<PipelineStageDto> get stages {
  if (_stages is EqualUnmodifiableListView) return _stages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stages);
}


/// Create a copy of PipelineDescribeDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PipelineDescribeDtoCopyWith<_PipelineDescribeDto> get copyWith => __$PipelineDescribeDtoCopyWithImpl<_PipelineDescribeDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PipelineDescribeDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PipelineDescribeDto&&const DeepCollectionEquality().equals(other._stages, _stages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_stages));

@override
String toString() {
  return 'PipelineDescribeDto(stages: $stages)';
}


}

/// @nodoc
abstract mixin class _$PipelineDescribeDtoCopyWith<$Res> implements $PipelineDescribeDtoCopyWith<$Res> {
  factory _$PipelineDescribeDtoCopyWith(_PipelineDescribeDto value, $Res Function(_PipelineDescribeDto) _then) = __$PipelineDescribeDtoCopyWithImpl;
@override @useResult
$Res call({
 List<PipelineStageDto> stages
});




}
/// @nodoc
class __$PipelineDescribeDtoCopyWithImpl<$Res>
    implements _$PipelineDescribeDtoCopyWith<$Res> {
  __$PipelineDescribeDtoCopyWithImpl(this._self, this._then);

  final _PipelineDescribeDto _self;
  final $Res Function(_PipelineDescribeDto) _then;

/// Create a copy of PipelineDescribeDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stages = null,}) {
  return _then(_PipelineDescribeDto(
stages: null == stages ? _self._stages : stages // ignore: cast_nullable_to_non_nullable
as List<PipelineStageDto>,
  ));
}


}


/// @nodoc
mixin _$PipelineStageDto {

 String get id; String get name; String get status; int? get durationMillis;
/// Create a copy of PipelineStageDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PipelineStageDtoCopyWith<PipelineStageDto> get copyWith => _$PipelineStageDtoCopyWithImpl<PipelineStageDto>(this as PipelineStageDto, _$identity);

  /// Serializes this PipelineStageDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PipelineStageDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.durationMillis, durationMillis) || other.durationMillis == durationMillis));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,status,durationMillis);

@override
String toString() {
  return 'PipelineStageDto(id: $id, name: $name, status: $status, durationMillis: $durationMillis)';
}


}

/// @nodoc
abstract mixin class $PipelineStageDtoCopyWith<$Res>  {
  factory $PipelineStageDtoCopyWith(PipelineStageDto value, $Res Function(PipelineStageDto) _then) = _$PipelineStageDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String status, int? durationMillis
});




}
/// @nodoc
class _$PipelineStageDtoCopyWithImpl<$Res>
    implements $PipelineStageDtoCopyWith<$Res> {
  _$PipelineStageDtoCopyWithImpl(this._self, this._then);

  final PipelineStageDto _self;
  final $Res Function(PipelineStageDto) _then;

/// Create a copy of PipelineStageDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? status = null,Object? durationMillis = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,durationMillis: freezed == durationMillis ? _self.durationMillis : durationMillis // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PipelineStageDto].
extension PipelineStageDtoPatterns on PipelineStageDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PipelineStageDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PipelineStageDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PipelineStageDto value)  $default,){
final _that = this;
switch (_that) {
case _PipelineStageDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PipelineStageDto value)?  $default,){
final _that = this;
switch (_that) {
case _PipelineStageDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String status,  int? durationMillis)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PipelineStageDto() when $default != null:
return $default(_that.id,_that.name,_that.status,_that.durationMillis);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String status,  int? durationMillis)  $default,) {final _that = this;
switch (_that) {
case _PipelineStageDto():
return $default(_that.id,_that.name,_that.status,_that.durationMillis);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String status,  int? durationMillis)?  $default,) {final _that = this;
switch (_that) {
case _PipelineStageDto() when $default != null:
return $default(_that.id,_that.name,_that.status,_that.durationMillis);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PipelineStageDto implements PipelineStageDto {
  const _PipelineStageDto({required this.id, required this.name, required this.status, this.durationMillis});
  factory _PipelineStageDto.fromJson(Map<String, dynamic> json) => _$PipelineStageDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  String status;
@override final  int? durationMillis;

/// Create a copy of PipelineStageDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PipelineStageDtoCopyWith<_PipelineStageDto> get copyWith => __$PipelineStageDtoCopyWithImpl<_PipelineStageDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PipelineStageDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PipelineStageDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.durationMillis, durationMillis) || other.durationMillis == durationMillis));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,status,durationMillis);

@override
String toString() {
  return 'PipelineStageDto(id: $id, name: $name, status: $status, durationMillis: $durationMillis)';
}


}

/// @nodoc
abstract mixin class _$PipelineStageDtoCopyWith<$Res> implements $PipelineStageDtoCopyWith<$Res> {
  factory _$PipelineStageDtoCopyWith(_PipelineStageDto value, $Res Function(_PipelineStageDto) _then) = __$PipelineStageDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String status, int? durationMillis
});




}
/// @nodoc
class __$PipelineStageDtoCopyWithImpl<$Res>
    implements _$PipelineStageDtoCopyWith<$Res> {
  __$PipelineStageDtoCopyWithImpl(this._self, this._then);

  final _PipelineStageDto _self;
  final $Res Function(_PipelineStageDto) _then;

/// Create a copy of PipelineStageDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? status = null,Object? durationMillis = freezed,}) {
  return _then(_PipelineStageDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,durationMillis: freezed == durationMillis ? _self.durationMillis : durationMillis // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
