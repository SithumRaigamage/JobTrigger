// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'jenkins_job_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JenkinsJobDto {

 String get name; String get url; String? get description; String? get color; List<JenkinsJobDto>? get jobs;// nested folders — see the null-vs-[] note above
 JenkinsBuildDto? get lastBuild; List<HealthReportDto>? get healthReport; List<JobPropertyDto>? get property;// holds parameterDefinitions
 List<JenkinsBuildDto>? get builds;
/// Create a copy of JenkinsJobDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JenkinsJobDtoCopyWith<JenkinsJobDto> get copyWith => _$JenkinsJobDtoCopyWithImpl<JenkinsJobDto>(this as JenkinsJobDto, _$identity);

  /// Serializes this JenkinsJobDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JenkinsJobDto&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url)&&(identical(other.description, description) || other.description == description)&&(identical(other.color, color) || other.color == color)&&const DeepCollectionEquality().equals(other.jobs, jobs)&&(identical(other.lastBuild, lastBuild) || other.lastBuild == lastBuild)&&const DeepCollectionEquality().equals(other.healthReport, healthReport)&&const DeepCollectionEquality().equals(other.property, property)&&const DeepCollectionEquality().equals(other.builds, builds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,url,description,color,const DeepCollectionEquality().hash(jobs),lastBuild,const DeepCollectionEquality().hash(healthReport),const DeepCollectionEquality().hash(property),const DeepCollectionEquality().hash(builds));

@override
String toString() {
  return 'JenkinsJobDto(name: $name, url: $url, description: $description, color: $color, jobs: $jobs, lastBuild: $lastBuild, healthReport: $healthReport, property: $property, builds: $builds)';
}


}

/// @nodoc
abstract mixin class $JenkinsJobDtoCopyWith<$Res>  {
  factory $JenkinsJobDtoCopyWith(JenkinsJobDto value, $Res Function(JenkinsJobDto) _then) = _$JenkinsJobDtoCopyWithImpl;
@useResult
$Res call({
 String name, String url, String? description, String? color, List<JenkinsJobDto>? jobs, JenkinsBuildDto? lastBuild, List<HealthReportDto>? healthReport, List<JobPropertyDto>? property, List<JenkinsBuildDto>? builds
});


$JenkinsBuildDtoCopyWith<$Res>? get lastBuild;

}
/// @nodoc
class _$JenkinsJobDtoCopyWithImpl<$Res>
    implements $JenkinsJobDtoCopyWith<$Res> {
  _$JenkinsJobDtoCopyWithImpl(this._self, this._then);

  final JenkinsJobDto _self;
  final $Res Function(JenkinsJobDto) _then;

/// Create a copy of JenkinsJobDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? url = null,Object? description = freezed,Object? color = freezed,Object? jobs = freezed,Object? lastBuild = freezed,Object? healthReport = freezed,Object? property = freezed,Object? builds = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,jobs: freezed == jobs ? _self.jobs : jobs // ignore: cast_nullable_to_non_nullable
as List<JenkinsJobDto>?,lastBuild: freezed == lastBuild ? _self.lastBuild : lastBuild // ignore: cast_nullable_to_non_nullable
as JenkinsBuildDto?,healthReport: freezed == healthReport ? _self.healthReport : healthReport // ignore: cast_nullable_to_non_nullable
as List<HealthReportDto>?,property: freezed == property ? _self.property : property // ignore: cast_nullable_to_non_nullable
as List<JobPropertyDto>?,builds: freezed == builds ? _self.builds : builds // ignore: cast_nullable_to_non_nullable
as List<JenkinsBuildDto>?,
  ));
}
/// Create a copy of JenkinsJobDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JenkinsBuildDtoCopyWith<$Res>? get lastBuild {
    if (_self.lastBuild == null) {
    return null;
  }

  return $JenkinsBuildDtoCopyWith<$Res>(_self.lastBuild!, (value) {
    return _then(_self.copyWith(lastBuild: value));
  });
}
}


/// Adds pattern-matching-related methods to [JenkinsJobDto].
extension JenkinsJobDtoPatterns on JenkinsJobDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JenkinsJobDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JenkinsJobDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JenkinsJobDto value)  $default,){
final _that = this;
switch (_that) {
case _JenkinsJobDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JenkinsJobDto value)?  $default,){
final _that = this;
switch (_that) {
case _JenkinsJobDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String url,  String? description,  String? color,  List<JenkinsJobDto>? jobs,  JenkinsBuildDto? lastBuild,  List<HealthReportDto>? healthReport,  List<JobPropertyDto>? property,  List<JenkinsBuildDto>? builds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JenkinsJobDto() when $default != null:
return $default(_that.name,_that.url,_that.description,_that.color,_that.jobs,_that.lastBuild,_that.healthReport,_that.property,_that.builds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String url,  String? description,  String? color,  List<JenkinsJobDto>? jobs,  JenkinsBuildDto? lastBuild,  List<HealthReportDto>? healthReport,  List<JobPropertyDto>? property,  List<JenkinsBuildDto>? builds)  $default,) {final _that = this;
switch (_that) {
case _JenkinsJobDto():
return $default(_that.name,_that.url,_that.description,_that.color,_that.jobs,_that.lastBuild,_that.healthReport,_that.property,_that.builds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String url,  String? description,  String? color,  List<JenkinsJobDto>? jobs,  JenkinsBuildDto? lastBuild,  List<HealthReportDto>? healthReport,  List<JobPropertyDto>? property,  List<JenkinsBuildDto>? builds)?  $default,) {final _that = this;
switch (_that) {
case _JenkinsJobDto() when $default != null:
return $default(_that.name,_that.url,_that.description,_that.color,_that.jobs,_that.lastBuild,_that.healthReport,_that.property,_that.builds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JenkinsJobDto implements JenkinsJobDto {
  const _JenkinsJobDto({required this.name, required this.url, this.description, this.color, final  List<JenkinsJobDto>? jobs, this.lastBuild, final  List<HealthReportDto>? healthReport = const [], final  List<JobPropertyDto>? property = const [], final  List<JenkinsBuildDto>? builds = const []}): _jobs = jobs,_healthReport = healthReport,_property = property,_builds = builds;
  factory _JenkinsJobDto.fromJson(Map<String, dynamic> json) => _$JenkinsJobDtoFromJson(json);

@override final  String name;
@override final  String url;
@override final  String? description;
@override final  String? color;
 final  List<JenkinsJobDto>? _jobs;
@override List<JenkinsJobDto>? get jobs {
  final value = _jobs;
  if (value == null) return null;
  if (_jobs is EqualUnmodifiableListView) return _jobs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

// nested folders — see the null-vs-[] note above
@override final  JenkinsBuildDto? lastBuild;
 final  List<HealthReportDto>? _healthReport;
@override@JsonKey() List<HealthReportDto>? get healthReport {
  final value = _healthReport;
  if (value == null) return null;
  if (_healthReport is EqualUnmodifiableListView) return _healthReport;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<JobPropertyDto>? _property;
@override@JsonKey() List<JobPropertyDto>? get property {
  final value = _property;
  if (value == null) return null;
  if (_property is EqualUnmodifiableListView) return _property;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

// holds parameterDefinitions
 final  List<JenkinsBuildDto>? _builds;
// holds parameterDefinitions
@override@JsonKey() List<JenkinsBuildDto>? get builds {
  final value = _builds;
  if (value == null) return null;
  if (_builds is EqualUnmodifiableListView) return _builds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of JenkinsJobDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JenkinsJobDtoCopyWith<_JenkinsJobDto> get copyWith => __$JenkinsJobDtoCopyWithImpl<_JenkinsJobDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JenkinsJobDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JenkinsJobDto&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url)&&(identical(other.description, description) || other.description == description)&&(identical(other.color, color) || other.color == color)&&const DeepCollectionEquality().equals(other._jobs, _jobs)&&(identical(other.lastBuild, lastBuild) || other.lastBuild == lastBuild)&&const DeepCollectionEquality().equals(other._healthReport, _healthReport)&&const DeepCollectionEquality().equals(other._property, _property)&&const DeepCollectionEquality().equals(other._builds, _builds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,url,description,color,const DeepCollectionEquality().hash(_jobs),lastBuild,const DeepCollectionEquality().hash(_healthReport),const DeepCollectionEquality().hash(_property),const DeepCollectionEquality().hash(_builds));

@override
String toString() {
  return 'JenkinsJobDto(name: $name, url: $url, description: $description, color: $color, jobs: $jobs, lastBuild: $lastBuild, healthReport: $healthReport, property: $property, builds: $builds)';
}


}

/// @nodoc
abstract mixin class _$JenkinsJobDtoCopyWith<$Res> implements $JenkinsJobDtoCopyWith<$Res> {
  factory _$JenkinsJobDtoCopyWith(_JenkinsJobDto value, $Res Function(_JenkinsJobDto) _then) = __$JenkinsJobDtoCopyWithImpl;
@override @useResult
$Res call({
 String name, String url, String? description, String? color, List<JenkinsJobDto>? jobs, JenkinsBuildDto? lastBuild, List<HealthReportDto>? healthReport, List<JobPropertyDto>? property, List<JenkinsBuildDto>? builds
});


@override $JenkinsBuildDtoCopyWith<$Res>? get lastBuild;

}
/// @nodoc
class __$JenkinsJobDtoCopyWithImpl<$Res>
    implements _$JenkinsJobDtoCopyWith<$Res> {
  __$JenkinsJobDtoCopyWithImpl(this._self, this._then);

  final _JenkinsJobDto _self;
  final $Res Function(_JenkinsJobDto) _then;

/// Create a copy of JenkinsJobDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? url = null,Object? description = freezed,Object? color = freezed,Object? jobs = freezed,Object? lastBuild = freezed,Object? healthReport = freezed,Object? property = freezed,Object? builds = freezed,}) {
  return _then(_JenkinsJobDto(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,jobs: freezed == jobs ? _self._jobs : jobs // ignore: cast_nullable_to_non_nullable
as List<JenkinsJobDto>?,lastBuild: freezed == lastBuild ? _self.lastBuild : lastBuild // ignore: cast_nullable_to_non_nullable
as JenkinsBuildDto?,healthReport: freezed == healthReport ? _self._healthReport : healthReport // ignore: cast_nullable_to_non_nullable
as List<HealthReportDto>?,property: freezed == property ? _self._property : property // ignore: cast_nullable_to_non_nullable
as List<JobPropertyDto>?,builds: freezed == builds ? _self._builds : builds // ignore: cast_nullable_to_non_nullable
as List<JenkinsBuildDto>?,
  ));
}

/// Create a copy of JenkinsJobDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JenkinsBuildDtoCopyWith<$Res>? get lastBuild {
    if (_self.lastBuild == null) {
    return null;
  }

  return $JenkinsBuildDtoCopyWith<$Res>(_self.lastBuild!, (value) {
    return _then(_self.copyWith(lastBuild: value));
  });
}
}

// dart format on
