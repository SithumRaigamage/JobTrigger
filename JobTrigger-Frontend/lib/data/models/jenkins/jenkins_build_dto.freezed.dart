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
 double? get duration; double? get estimatedDuration; bool get building; String? get displayName;// US-PIPE-02: Jenkins' `actions` array is polymorphic -- only some
// entries are a `hudson.model.CauseAction` carrying `causes`, and the
// tree query (`actions[causes[shortDescription]]`) still returns every
// action entry, just pruned to that one field where present. Flatten
// straight to the description strings we actually render rather than
// modeling the full heterogeneous `actions` shape.
@JsonKey(name: 'actions', fromJson: _causesFromJson) List<String> get causes;// US-PIPE-03: `changeSet` is `{"items": [...], "kind": "..."}` — only
// `items` (each `{msg, author: {fullName}}`) is requested/parsed;
// `kind` isn't rendered anywhere so it's left off the tree query.
// `ScmChange` isn't JSON-serializable itself (no toJson) -- fine, since
// this DTO is response-only and never re-encoded; `includeToJson:
// false` tells json_serializable not to try.
@JsonKey(name: 'changeSet', fromJson: _changesFromJson, includeToJson: false) List<ScmChange> get changes;// US-PIPE-07: `artifacts[]` is a flat, non-polymorphic array directly
// on the build resource -- unlike causes/changes above, no custom
// unwrapper needed, just a nested DTO.
 List<BuildArtifactDto> get artifacts;
/// Create a copy of JenkinsBuildDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JenkinsBuildDtoCopyWith<JenkinsBuildDto> get copyWith => _$JenkinsBuildDtoCopyWithImpl<JenkinsBuildDto>(this as JenkinsBuildDto, _$identity);

  /// Serializes this JenkinsBuildDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JenkinsBuildDto&&(identical(other.number, number) || other.number == number)&&(identical(other.url, url) || other.url == url)&&(identical(other.result, result) || other.result == result)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.estimatedDuration, estimatedDuration) || other.estimatedDuration == estimatedDuration)&&(identical(other.building, building) || other.building == building)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&const DeepCollectionEquality().equals(other.causes, causes)&&const DeepCollectionEquality().equals(other.changes, changes)&&const DeepCollectionEquality().equals(other.artifacts, artifacts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,url,result,timestamp,duration,estimatedDuration,building,displayName,const DeepCollectionEquality().hash(causes),const DeepCollectionEquality().hash(changes),const DeepCollectionEquality().hash(artifacts));

@override
String toString() {
  return 'JenkinsBuildDto(number: $number, url: $url, result: $result, timestamp: $timestamp, duration: $duration, estimatedDuration: $estimatedDuration, building: $building, displayName: $displayName, causes: $causes, changes: $changes, artifacts: $artifacts)';
}


}

/// @nodoc
abstract mixin class $JenkinsBuildDtoCopyWith<$Res>  {
  factory $JenkinsBuildDtoCopyWith(JenkinsBuildDto value, $Res Function(JenkinsBuildDto) _then) = _$JenkinsBuildDtoCopyWithImpl;
@useResult
$Res call({
 int number, String url, String? result, double timestamp, double? duration, double? estimatedDuration, bool building, String? displayName,@JsonKey(name: 'actions', fromJson: _causesFromJson) List<String> causes,@JsonKey(name: 'changeSet', fromJson: _changesFromJson, includeToJson: false) List<ScmChange> changes, List<BuildArtifactDto> artifacts
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
@pragma('vm:prefer-inline') @override $Res call({Object? number = null,Object? url = null,Object? result = freezed,Object? timestamp = null,Object? duration = freezed,Object? estimatedDuration = freezed,Object? building = null,Object? displayName = freezed,Object? causes = null,Object? changes = null,Object? artifacts = null,}) {
  return _then(_self.copyWith(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as double,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as double?,estimatedDuration: freezed == estimatedDuration ? _self.estimatedDuration : estimatedDuration // ignore: cast_nullable_to_non_nullable
as double?,building: null == building ? _self.building : building // ignore: cast_nullable_to_non_nullable
as bool,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,causes: null == causes ? _self.causes : causes // ignore: cast_nullable_to_non_nullable
as List<String>,changes: null == changes ? _self.changes : changes // ignore: cast_nullable_to_non_nullable
as List<ScmChange>,artifacts: null == artifacts ? _self.artifacts : artifacts // ignore: cast_nullable_to_non_nullable
as List<BuildArtifactDto>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int number,  String url,  String? result,  double timestamp,  double? duration,  double? estimatedDuration,  bool building,  String? displayName, @JsonKey(name: 'actions', fromJson: _causesFromJson)  List<String> causes, @JsonKey(name: 'changeSet', fromJson: _changesFromJson, includeToJson: false)  List<ScmChange> changes,  List<BuildArtifactDto> artifacts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JenkinsBuildDto() when $default != null:
return $default(_that.number,_that.url,_that.result,_that.timestamp,_that.duration,_that.estimatedDuration,_that.building,_that.displayName,_that.causes,_that.changes,_that.artifacts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int number,  String url,  String? result,  double timestamp,  double? duration,  double? estimatedDuration,  bool building,  String? displayName, @JsonKey(name: 'actions', fromJson: _causesFromJson)  List<String> causes, @JsonKey(name: 'changeSet', fromJson: _changesFromJson, includeToJson: false)  List<ScmChange> changes,  List<BuildArtifactDto> artifacts)  $default,) {final _that = this;
switch (_that) {
case _JenkinsBuildDto():
return $default(_that.number,_that.url,_that.result,_that.timestamp,_that.duration,_that.estimatedDuration,_that.building,_that.displayName,_that.causes,_that.changes,_that.artifacts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int number,  String url,  String? result,  double timestamp,  double? duration,  double? estimatedDuration,  bool building,  String? displayName, @JsonKey(name: 'actions', fromJson: _causesFromJson)  List<String> causes, @JsonKey(name: 'changeSet', fromJson: _changesFromJson, includeToJson: false)  List<ScmChange> changes,  List<BuildArtifactDto> artifacts)?  $default,) {final _that = this;
switch (_that) {
case _JenkinsBuildDto() when $default != null:
return $default(_that.number,_that.url,_that.result,_that.timestamp,_that.duration,_that.estimatedDuration,_that.building,_that.displayName,_that.causes,_that.changes,_that.artifacts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JenkinsBuildDto implements JenkinsBuildDto {
  const _JenkinsBuildDto({required this.number, required this.url, this.result, required this.timestamp, this.duration, this.estimatedDuration, this.building = false, this.displayName, @JsonKey(name: 'actions', fromJson: _causesFromJson) final  List<String> causes = const <String>[], @JsonKey(name: 'changeSet', fromJson: _changesFromJson, includeToJson: false) final  List<ScmChange> changes = const <ScmChange>[], final  List<BuildArtifactDto> artifacts = const <BuildArtifactDto>[]}): _causes = causes,_changes = changes,_artifacts = artifacts;
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
// US-PIPE-02: Jenkins' `actions` array is polymorphic -- only some
// entries are a `hudson.model.CauseAction` carrying `causes`, and the
// tree query (`actions[causes[shortDescription]]`) still returns every
// action entry, just pruned to that one field where present. Flatten
// straight to the description strings we actually render rather than
// modeling the full heterogeneous `actions` shape.
 final  List<String> _causes;
// US-PIPE-02: Jenkins' `actions` array is polymorphic -- only some
// entries are a `hudson.model.CauseAction` carrying `causes`, and the
// tree query (`actions[causes[shortDescription]]`) still returns every
// action entry, just pruned to that one field where present. Flatten
// straight to the description strings we actually render rather than
// modeling the full heterogeneous `actions` shape.
@override@JsonKey(name: 'actions', fromJson: _causesFromJson) List<String> get causes {
  if (_causes is EqualUnmodifiableListView) return _causes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_causes);
}

// US-PIPE-03: `changeSet` is `{"items": [...], "kind": "..."}` — only
// `items` (each `{msg, author: {fullName}}`) is requested/parsed;
// `kind` isn't rendered anywhere so it's left off the tree query.
// `ScmChange` isn't JSON-serializable itself (no toJson) -- fine, since
// this DTO is response-only and never re-encoded; `includeToJson:
// false` tells json_serializable not to try.
 final  List<ScmChange> _changes;
// US-PIPE-03: `changeSet` is `{"items": [...], "kind": "..."}` — only
// `items` (each `{msg, author: {fullName}}`) is requested/parsed;
// `kind` isn't rendered anywhere so it's left off the tree query.
// `ScmChange` isn't JSON-serializable itself (no toJson) -- fine, since
// this DTO is response-only and never re-encoded; `includeToJson:
// false` tells json_serializable not to try.
@override@JsonKey(name: 'changeSet', fromJson: _changesFromJson, includeToJson: false) List<ScmChange> get changes {
  if (_changes is EqualUnmodifiableListView) return _changes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_changes);
}

// US-PIPE-07: `artifacts[]` is a flat, non-polymorphic array directly
// on the build resource -- unlike causes/changes above, no custom
// unwrapper needed, just a nested DTO.
 final  List<BuildArtifactDto> _artifacts;
// US-PIPE-07: `artifacts[]` is a flat, non-polymorphic array directly
// on the build resource -- unlike causes/changes above, no custom
// unwrapper needed, just a nested DTO.
@override@JsonKey() List<BuildArtifactDto> get artifacts {
  if (_artifacts is EqualUnmodifiableListView) return _artifacts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_artifacts);
}


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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JenkinsBuildDto&&(identical(other.number, number) || other.number == number)&&(identical(other.url, url) || other.url == url)&&(identical(other.result, result) || other.result == result)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.estimatedDuration, estimatedDuration) || other.estimatedDuration == estimatedDuration)&&(identical(other.building, building) || other.building == building)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&const DeepCollectionEquality().equals(other._causes, _causes)&&const DeepCollectionEquality().equals(other._changes, _changes)&&const DeepCollectionEquality().equals(other._artifacts, _artifacts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,url,result,timestamp,duration,estimatedDuration,building,displayName,const DeepCollectionEquality().hash(_causes),const DeepCollectionEquality().hash(_changes),const DeepCollectionEquality().hash(_artifacts));

@override
String toString() {
  return 'JenkinsBuildDto(number: $number, url: $url, result: $result, timestamp: $timestamp, duration: $duration, estimatedDuration: $estimatedDuration, building: $building, displayName: $displayName, causes: $causes, changes: $changes, artifacts: $artifacts)';
}


}

/// @nodoc
abstract mixin class _$JenkinsBuildDtoCopyWith<$Res> implements $JenkinsBuildDtoCopyWith<$Res> {
  factory _$JenkinsBuildDtoCopyWith(_JenkinsBuildDto value, $Res Function(_JenkinsBuildDto) _then) = __$JenkinsBuildDtoCopyWithImpl;
@override @useResult
$Res call({
 int number, String url, String? result, double timestamp, double? duration, double? estimatedDuration, bool building, String? displayName,@JsonKey(name: 'actions', fromJson: _causesFromJson) List<String> causes,@JsonKey(name: 'changeSet', fromJson: _changesFromJson, includeToJson: false) List<ScmChange> changes, List<BuildArtifactDto> artifacts
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
@override @pragma('vm:prefer-inline') $Res call({Object? number = null,Object? url = null,Object? result = freezed,Object? timestamp = null,Object? duration = freezed,Object? estimatedDuration = freezed,Object? building = null,Object? displayName = freezed,Object? causes = null,Object? changes = null,Object? artifacts = null,}) {
  return _then(_JenkinsBuildDto(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as double,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as double?,estimatedDuration: freezed == estimatedDuration ? _self.estimatedDuration : estimatedDuration // ignore: cast_nullable_to_non_nullable
as double?,building: null == building ? _self.building : building // ignore: cast_nullable_to_non_nullable
as bool,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,causes: null == causes ? _self._causes : causes // ignore: cast_nullable_to_non_nullable
as List<String>,changes: null == changes ? _self._changes : changes // ignore: cast_nullable_to_non_nullable
as List<ScmChange>,artifacts: null == artifacts ? _self._artifacts : artifacts // ignore: cast_nullable_to_non_nullable
as List<BuildArtifactDto>,
  ));
}


}


/// @nodoc
mixin _$BuildArtifactDto {

 String get fileName; String get relativePath;
/// Create a copy of BuildArtifactDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuildArtifactDtoCopyWith<BuildArtifactDto> get copyWith => _$BuildArtifactDtoCopyWithImpl<BuildArtifactDto>(this as BuildArtifactDto, _$identity);

  /// Serializes this BuildArtifactDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuildArtifactDto&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.relativePath, relativePath) || other.relativePath == relativePath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileName,relativePath);

@override
String toString() {
  return 'BuildArtifactDto(fileName: $fileName, relativePath: $relativePath)';
}


}

/// @nodoc
abstract mixin class $BuildArtifactDtoCopyWith<$Res>  {
  factory $BuildArtifactDtoCopyWith(BuildArtifactDto value, $Res Function(BuildArtifactDto) _then) = _$BuildArtifactDtoCopyWithImpl;
@useResult
$Res call({
 String fileName, String relativePath
});




}
/// @nodoc
class _$BuildArtifactDtoCopyWithImpl<$Res>
    implements $BuildArtifactDtoCopyWith<$Res> {
  _$BuildArtifactDtoCopyWithImpl(this._self, this._then);

  final BuildArtifactDto _self;
  final $Res Function(BuildArtifactDto) _then;

/// Create a copy of BuildArtifactDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileName = null,Object? relativePath = null,}) {
  return _then(_self.copyWith(
fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,relativePath: null == relativePath ? _self.relativePath : relativePath // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BuildArtifactDto].
extension BuildArtifactDtoPatterns on BuildArtifactDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuildArtifactDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuildArtifactDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuildArtifactDto value)  $default,){
final _that = this;
switch (_that) {
case _BuildArtifactDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuildArtifactDto value)?  $default,){
final _that = this;
switch (_that) {
case _BuildArtifactDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fileName,  String relativePath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuildArtifactDto() when $default != null:
return $default(_that.fileName,_that.relativePath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fileName,  String relativePath)  $default,) {final _that = this;
switch (_that) {
case _BuildArtifactDto():
return $default(_that.fileName,_that.relativePath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fileName,  String relativePath)?  $default,) {final _that = this;
switch (_that) {
case _BuildArtifactDto() when $default != null:
return $default(_that.fileName,_that.relativePath);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuildArtifactDto implements BuildArtifactDto {
  const _BuildArtifactDto({required this.fileName, required this.relativePath});
  factory _BuildArtifactDto.fromJson(Map<String, dynamic> json) => _$BuildArtifactDtoFromJson(json);

@override final  String fileName;
@override final  String relativePath;

/// Create a copy of BuildArtifactDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuildArtifactDtoCopyWith<_BuildArtifactDto> get copyWith => __$BuildArtifactDtoCopyWithImpl<_BuildArtifactDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuildArtifactDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuildArtifactDto&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.relativePath, relativePath) || other.relativePath == relativePath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileName,relativePath);

@override
String toString() {
  return 'BuildArtifactDto(fileName: $fileName, relativePath: $relativePath)';
}


}

/// @nodoc
abstract mixin class _$BuildArtifactDtoCopyWith<$Res> implements $BuildArtifactDtoCopyWith<$Res> {
  factory _$BuildArtifactDtoCopyWith(_BuildArtifactDto value, $Res Function(_BuildArtifactDto) _then) = __$BuildArtifactDtoCopyWithImpl;
@override @useResult
$Res call({
 String fileName, String relativePath
});




}
/// @nodoc
class __$BuildArtifactDtoCopyWithImpl<$Res>
    implements _$BuildArtifactDtoCopyWith<$Res> {
  __$BuildArtifactDtoCopyWithImpl(this._self, this._then);

  final _BuildArtifactDto _self;
  final $Res Function(_BuildArtifactDto) _then;

/// Create a copy of BuildArtifactDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileName = null,Object? relativePath = null,}) {
  return _then(_BuildArtifactDto(
fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,relativePath: null == relativePath ? _self.relativePath : relativePath // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
