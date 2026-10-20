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

 String get id; String get name; String get status; int? get durationMillis; int? get startTimeMillis; PipelineErrorDto? get error;// Present on `execution/node/{id}/wfapi/describe`, absent on the
// build-level describe.
 List<PipelineStepDto> get stageFlowNodes;
/// Create a copy of PipelineStageDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PipelineStageDtoCopyWith<PipelineStageDto> get copyWith => _$PipelineStageDtoCopyWithImpl<PipelineStageDto>(this as PipelineStageDto, _$identity);

  /// Serializes this PipelineStageDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PipelineStageDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.durationMillis, durationMillis) || other.durationMillis == durationMillis)&&(identical(other.startTimeMillis, startTimeMillis) || other.startTimeMillis == startTimeMillis)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other.stageFlowNodes, stageFlowNodes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,status,durationMillis,startTimeMillis,error,const DeepCollectionEquality().hash(stageFlowNodes));

@override
String toString() {
  return 'PipelineStageDto(id: $id, name: $name, status: $status, durationMillis: $durationMillis, startTimeMillis: $startTimeMillis, error: $error, stageFlowNodes: $stageFlowNodes)';
}


}

/// @nodoc
abstract mixin class $PipelineStageDtoCopyWith<$Res>  {
  factory $PipelineStageDtoCopyWith(PipelineStageDto value, $Res Function(PipelineStageDto) _then) = _$PipelineStageDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String status, int? durationMillis, int? startTimeMillis, PipelineErrorDto? error, List<PipelineStepDto> stageFlowNodes
});


$PipelineErrorDtoCopyWith<$Res>? get error;

}
/// @nodoc
class _$PipelineStageDtoCopyWithImpl<$Res>
    implements $PipelineStageDtoCopyWith<$Res> {
  _$PipelineStageDtoCopyWithImpl(this._self, this._then);

  final PipelineStageDto _self;
  final $Res Function(PipelineStageDto) _then;

/// Create a copy of PipelineStageDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? status = null,Object? durationMillis = freezed,Object? startTimeMillis = freezed,Object? error = freezed,Object? stageFlowNodes = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,durationMillis: freezed == durationMillis ? _self.durationMillis : durationMillis // ignore: cast_nullable_to_non_nullable
as int?,startTimeMillis: freezed == startTimeMillis ? _self.startTimeMillis : startTimeMillis // ignore: cast_nullable_to_non_nullable
as int?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as PipelineErrorDto?,stageFlowNodes: null == stageFlowNodes ? _self.stageFlowNodes : stageFlowNodes // ignore: cast_nullable_to_non_nullable
as List<PipelineStepDto>,
  ));
}
/// Create a copy of PipelineStageDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PipelineErrorDtoCopyWith<$Res>? get error {
    if (_self.error == null) {
    return null;
  }

  return $PipelineErrorDtoCopyWith<$Res>(_self.error!, (value) {
    return _then(_self.copyWith(error: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String status,  int? durationMillis,  int? startTimeMillis,  PipelineErrorDto? error,  List<PipelineStepDto> stageFlowNodes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PipelineStageDto() when $default != null:
return $default(_that.id,_that.name,_that.status,_that.durationMillis,_that.startTimeMillis,_that.error,_that.stageFlowNodes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String status,  int? durationMillis,  int? startTimeMillis,  PipelineErrorDto? error,  List<PipelineStepDto> stageFlowNodes)  $default,) {final _that = this;
switch (_that) {
case _PipelineStageDto():
return $default(_that.id,_that.name,_that.status,_that.durationMillis,_that.startTimeMillis,_that.error,_that.stageFlowNodes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String status,  int? durationMillis,  int? startTimeMillis,  PipelineErrorDto? error,  List<PipelineStepDto> stageFlowNodes)?  $default,) {final _that = this;
switch (_that) {
case _PipelineStageDto() when $default != null:
return $default(_that.id,_that.name,_that.status,_that.durationMillis,_that.startTimeMillis,_that.error,_that.stageFlowNodes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PipelineStageDto implements PipelineStageDto {
  const _PipelineStageDto({required this.id, required this.name, required this.status, this.durationMillis, this.startTimeMillis, this.error, final  List<PipelineStepDto> stageFlowNodes = const <PipelineStepDto>[]}): _stageFlowNodes = stageFlowNodes;
  factory _PipelineStageDto.fromJson(Map<String, dynamic> json) => _$PipelineStageDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  String status;
@override final  int? durationMillis;
@override final  int? startTimeMillis;
@override final  PipelineErrorDto? error;
// Present on `execution/node/{id}/wfapi/describe`, absent on the
// build-level describe.
 final  List<PipelineStepDto> _stageFlowNodes;
// Present on `execution/node/{id}/wfapi/describe`, absent on the
// build-level describe.
@override@JsonKey() List<PipelineStepDto> get stageFlowNodes {
  if (_stageFlowNodes is EqualUnmodifiableListView) return _stageFlowNodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stageFlowNodes);
}


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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PipelineStageDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.durationMillis, durationMillis) || other.durationMillis == durationMillis)&&(identical(other.startTimeMillis, startTimeMillis) || other.startTimeMillis == startTimeMillis)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other._stageFlowNodes, _stageFlowNodes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,status,durationMillis,startTimeMillis,error,const DeepCollectionEquality().hash(_stageFlowNodes));

@override
String toString() {
  return 'PipelineStageDto(id: $id, name: $name, status: $status, durationMillis: $durationMillis, startTimeMillis: $startTimeMillis, error: $error, stageFlowNodes: $stageFlowNodes)';
}


}

/// @nodoc
abstract mixin class _$PipelineStageDtoCopyWith<$Res> implements $PipelineStageDtoCopyWith<$Res> {
  factory _$PipelineStageDtoCopyWith(_PipelineStageDto value, $Res Function(_PipelineStageDto) _then) = __$PipelineStageDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String status, int? durationMillis, int? startTimeMillis, PipelineErrorDto? error, List<PipelineStepDto> stageFlowNodes
});


@override $PipelineErrorDtoCopyWith<$Res>? get error;

}
/// @nodoc
class __$PipelineStageDtoCopyWithImpl<$Res>
    implements _$PipelineStageDtoCopyWith<$Res> {
  __$PipelineStageDtoCopyWithImpl(this._self, this._then);

  final _PipelineStageDto _self;
  final $Res Function(_PipelineStageDto) _then;

/// Create a copy of PipelineStageDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? status = null,Object? durationMillis = freezed,Object? startTimeMillis = freezed,Object? error = freezed,Object? stageFlowNodes = null,}) {
  return _then(_PipelineStageDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,durationMillis: freezed == durationMillis ? _self.durationMillis : durationMillis // ignore: cast_nullable_to_non_nullable
as int?,startTimeMillis: freezed == startTimeMillis ? _self.startTimeMillis : startTimeMillis // ignore: cast_nullable_to_non_nullable
as int?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as PipelineErrorDto?,stageFlowNodes: null == stageFlowNodes ? _self._stageFlowNodes : stageFlowNodes // ignore: cast_nullable_to_non_nullable
as List<PipelineStepDto>,
  ));
}

/// Create a copy of PipelineStageDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PipelineErrorDtoCopyWith<$Res>? get error {
    if (_self.error == null) {
    return null;
  }

  return $PipelineErrorDtoCopyWith<$Res>(_self.error!, (value) {
    return _then(_self.copyWith(error: value));
  });
}
}


/// @nodoc
mixin _$PipelineErrorDto {

 String? get message;
/// Create a copy of PipelineErrorDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PipelineErrorDtoCopyWith<PipelineErrorDto> get copyWith => _$PipelineErrorDtoCopyWithImpl<PipelineErrorDto>(this as PipelineErrorDto, _$identity);

  /// Serializes this PipelineErrorDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PipelineErrorDto&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'PipelineErrorDto(message: $message)';
}


}

/// @nodoc
abstract mixin class $PipelineErrorDtoCopyWith<$Res>  {
  factory $PipelineErrorDtoCopyWith(PipelineErrorDto value, $Res Function(PipelineErrorDto) _then) = _$PipelineErrorDtoCopyWithImpl;
@useResult
$Res call({
 String? message
});




}
/// @nodoc
class _$PipelineErrorDtoCopyWithImpl<$Res>
    implements $PipelineErrorDtoCopyWith<$Res> {
  _$PipelineErrorDtoCopyWithImpl(this._self, this._then);

  final PipelineErrorDto _self;
  final $Res Function(PipelineErrorDto) _then;

/// Create a copy of PipelineErrorDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = freezed,}) {
  return _then(_self.copyWith(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PipelineErrorDto].
extension PipelineErrorDtoPatterns on PipelineErrorDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PipelineErrorDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PipelineErrorDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PipelineErrorDto value)  $default,){
final _that = this;
switch (_that) {
case _PipelineErrorDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PipelineErrorDto value)?  $default,){
final _that = this;
switch (_that) {
case _PipelineErrorDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PipelineErrorDto() when $default != null:
return $default(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? message)  $default,) {final _that = this;
switch (_that) {
case _PipelineErrorDto():
return $default(_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? message)?  $default,) {final _that = this;
switch (_that) {
case _PipelineErrorDto() when $default != null:
return $default(_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PipelineErrorDto implements PipelineErrorDto {
  const _PipelineErrorDto({this.message});
  factory _PipelineErrorDto.fromJson(Map<String, dynamic> json) => _$PipelineErrorDtoFromJson(json);

@override final  String? message;

/// Create a copy of PipelineErrorDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PipelineErrorDtoCopyWith<_PipelineErrorDto> get copyWith => __$PipelineErrorDtoCopyWithImpl<_PipelineErrorDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PipelineErrorDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PipelineErrorDto&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'PipelineErrorDto(message: $message)';
}


}

/// @nodoc
abstract mixin class _$PipelineErrorDtoCopyWith<$Res> implements $PipelineErrorDtoCopyWith<$Res> {
  factory _$PipelineErrorDtoCopyWith(_PipelineErrorDto value, $Res Function(_PipelineErrorDto) _then) = __$PipelineErrorDtoCopyWithImpl;
@override @useResult
$Res call({
 String? message
});




}
/// @nodoc
class __$PipelineErrorDtoCopyWithImpl<$Res>
    implements _$PipelineErrorDtoCopyWith<$Res> {
  __$PipelineErrorDtoCopyWithImpl(this._self, this._then);

  final _PipelineErrorDto _self;
  final $Res Function(_PipelineErrorDto) _then;

/// Create a copy of PipelineErrorDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,}) {
  return _then(_PipelineErrorDto(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PipelineStepDto {

 String get id; String get name; String get status; String? get parameterDescription; int? get durationMillis;
/// Create a copy of PipelineStepDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PipelineStepDtoCopyWith<PipelineStepDto> get copyWith => _$PipelineStepDtoCopyWithImpl<PipelineStepDto>(this as PipelineStepDto, _$identity);

  /// Serializes this PipelineStepDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PipelineStepDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.parameterDescription, parameterDescription) || other.parameterDescription == parameterDescription)&&(identical(other.durationMillis, durationMillis) || other.durationMillis == durationMillis));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,status,parameterDescription,durationMillis);

@override
String toString() {
  return 'PipelineStepDto(id: $id, name: $name, status: $status, parameterDescription: $parameterDescription, durationMillis: $durationMillis)';
}


}

/// @nodoc
abstract mixin class $PipelineStepDtoCopyWith<$Res>  {
  factory $PipelineStepDtoCopyWith(PipelineStepDto value, $Res Function(PipelineStepDto) _then) = _$PipelineStepDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String status, String? parameterDescription, int? durationMillis
});




}
/// @nodoc
class _$PipelineStepDtoCopyWithImpl<$Res>
    implements $PipelineStepDtoCopyWith<$Res> {
  _$PipelineStepDtoCopyWithImpl(this._self, this._then);

  final PipelineStepDto _self;
  final $Res Function(PipelineStepDto) _then;

/// Create a copy of PipelineStepDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? status = null,Object? parameterDescription = freezed,Object? durationMillis = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,parameterDescription: freezed == parameterDescription ? _self.parameterDescription : parameterDescription // ignore: cast_nullable_to_non_nullable
as String?,durationMillis: freezed == durationMillis ? _self.durationMillis : durationMillis // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PipelineStepDto].
extension PipelineStepDtoPatterns on PipelineStepDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PipelineStepDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PipelineStepDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PipelineStepDto value)  $default,){
final _that = this;
switch (_that) {
case _PipelineStepDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PipelineStepDto value)?  $default,){
final _that = this;
switch (_that) {
case _PipelineStepDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String status,  String? parameterDescription,  int? durationMillis)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PipelineStepDto() when $default != null:
return $default(_that.id,_that.name,_that.status,_that.parameterDescription,_that.durationMillis);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String status,  String? parameterDescription,  int? durationMillis)  $default,) {final _that = this;
switch (_that) {
case _PipelineStepDto():
return $default(_that.id,_that.name,_that.status,_that.parameterDescription,_that.durationMillis);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String status,  String? parameterDescription,  int? durationMillis)?  $default,) {final _that = this;
switch (_that) {
case _PipelineStepDto() when $default != null:
return $default(_that.id,_that.name,_that.status,_that.parameterDescription,_that.durationMillis);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PipelineStepDto implements PipelineStepDto {
  const _PipelineStepDto({required this.id, required this.name, required this.status, this.parameterDescription, this.durationMillis});
  factory _PipelineStepDto.fromJson(Map<String, dynamic> json) => _$PipelineStepDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  String status;
@override final  String? parameterDescription;
@override final  int? durationMillis;

/// Create a copy of PipelineStepDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PipelineStepDtoCopyWith<_PipelineStepDto> get copyWith => __$PipelineStepDtoCopyWithImpl<_PipelineStepDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PipelineStepDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PipelineStepDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.parameterDescription, parameterDescription) || other.parameterDescription == parameterDescription)&&(identical(other.durationMillis, durationMillis) || other.durationMillis == durationMillis));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,status,parameterDescription,durationMillis);

@override
String toString() {
  return 'PipelineStepDto(id: $id, name: $name, status: $status, parameterDescription: $parameterDescription, durationMillis: $durationMillis)';
}


}

/// @nodoc
abstract mixin class _$PipelineStepDtoCopyWith<$Res> implements $PipelineStepDtoCopyWith<$Res> {
  factory _$PipelineStepDtoCopyWith(_PipelineStepDto value, $Res Function(_PipelineStepDto) _then) = __$PipelineStepDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String status, String? parameterDescription, int? durationMillis
});




}
/// @nodoc
class __$PipelineStepDtoCopyWithImpl<$Res>
    implements _$PipelineStepDtoCopyWith<$Res> {
  __$PipelineStepDtoCopyWithImpl(this._self, this._then);

  final _PipelineStepDto _self;
  final $Res Function(_PipelineStepDto) _then;

/// Create a copy of PipelineStepDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? status = null,Object? parameterDescription = freezed,Object? durationMillis = freezed,}) {
  return _then(_PipelineStepDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,parameterDescription: freezed == parameterDescription ? _self.parameterDescription : parameterDescription // ignore: cast_nullable_to_non_nullable
as String?,durationMillis: freezed == durationMillis ? _self.durationMillis : durationMillis // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$StepLogDto {

 String get text; bool get hasMore;
/// Create a copy of StepLogDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StepLogDtoCopyWith<StepLogDto> get copyWith => _$StepLogDtoCopyWithImpl<StepLogDto>(this as StepLogDto, _$identity);

  /// Serializes this StepLogDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StepLogDto&&(identical(other.text, text) || other.text == text)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,hasMore);

@override
String toString() {
  return 'StepLogDto(text: $text, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class $StepLogDtoCopyWith<$Res>  {
  factory $StepLogDtoCopyWith(StepLogDto value, $Res Function(StepLogDto) _then) = _$StepLogDtoCopyWithImpl;
@useResult
$Res call({
 String text, bool hasMore
});




}
/// @nodoc
class _$StepLogDtoCopyWithImpl<$Res>
    implements $StepLogDtoCopyWith<$Res> {
  _$StepLogDtoCopyWithImpl(this._self, this._then);

  final StepLogDto _self;
  final $Res Function(StepLogDto) _then;

/// Create a copy of StepLogDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? hasMore = null,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [StepLogDto].
extension StepLogDtoPatterns on StepLogDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StepLogDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StepLogDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StepLogDto value)  $default,){
final _that = this;
switch (_that) {
case _StepLogDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StepLogDto value)?  $default,){
final _that = this;
switch (_that) {
case _StepLogDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  bool hasMore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StepLogDto() when $default != null:
return $default(_that.text,_that.hasMore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  bool hasMore)  $default,) {final _that = this;
switch (_that) {
case _StepLogDto():
return $default(_that.text,_that.hasMore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  bool hasMore)?  $default,) {final _that = this;
switch (_that) {
case _StepLogDto() when $default != null:
return $default(_that.text,_that.hasMore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StepLogDto implements StepLogDto {
  const _StepLogDto({this.text = '', this.hasMore = false});
  factory _StepLogDto.fromJson(Map<String, dynamic> json) => _$StepLogDtoFromJson(json);

@override@JsonKey() final  String text;
@override@JsonKey() final  bool hasMore;

/// Create a copy of StepLogDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StepLogDtoCopyWith<_StepLogDto> get copyWith => __$StepLogDtoCopyWithImpl<_StepLogDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StepLogDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StepLogDto&&(identical(other.text, text) || other.text == text)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,hasMore);

@override
String toString() {
  return 'StepLogDto(text: $text, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class _$StepLogDtoCopyWith<$Res> implements $StepLogDtoCopyWith<$Res> {
  factory _$StepLogDtoCopyWith(_StepLogDto value, $Res Function(_StepLogDto) _then) = __$StepLogDtoCopyWithImpl;
@override @useResult
$Res call({
 String text, bool hasMore
});




}
/// @nodoc
class __$StepLogDtoCopyWithImpl<$Res>
    implements _$StepLogDtoCopyWith<$Res> {
  __$StepLogDtoCopyWithImpl(this._self, this._then);

  final _StepLogDto _self;
  final $Res Function(_StepLogDto) _then;

/// Create a copy of StepLogDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? hasMore = null,}) {
  return _then(_StepLogDto(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
