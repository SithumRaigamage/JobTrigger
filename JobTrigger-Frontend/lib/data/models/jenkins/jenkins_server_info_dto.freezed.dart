// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'jenkins_server_info_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JenkinsServerInfoDto {

 String? get mode; String? get nodeDescription; int? get numExecutors; bool? get useSecurity; List<JenkinsJobDto> get jobs;
/// Create a copy of JenkinsServerInfoDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JenkinsServerInfoDtoCopyWith<JenkinsServerInfoDto> get copyWith => _$JenkinsServerInfoDtoCopyWithImpl<JenkinsServerInfoDto>(this as JenkinsServerInfoDto, _$identity);

  /// Serializes this JenkinsServerInfoDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JenkinsServerInfoDto&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.nodeDescription, nodeDescription) || other.nodeDescription == nodeDescription)&&(identical(other.numExecutors, numExecutors) || other.numExecutors == numExecutors)&&(identical(other.useSecurity, useSecurity) || other.useSecurity == useSecurity)&&const DeepCollectionEquality().equals(other.jobs, jobs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mode,nodeDescription,numExecutors,useSecurity,const DeepCollectionEquality().hash(jobs));

@override
String toString() {
  return 'JenkinsServerInfoDto(mode: $mode, nodeDescription: $nodeDescription, numExecutors: $numExecutors, useSecurity: $useSecurity, jobs: $jobs)';
}


}

/// @nodoc
abstract mixin class $JenkinsServerInfoDtoCopyWith<$Res>  {
  factory $JenkinsServerInfoDtoCopyWith(JenkinsServerInfoDto value, $Res Function(JenkinsServerInfoDto) _then) = _$JenkinsServerInfoDtoCopyWithImpl;
@useResult
$Res call({
 String? mode, String? nodeDescription, int? numExecutors, bool? useSecurity, List<JenkinsJobDto> jobs
});




}
/// @nodoc
class _$JenkinsServerInfoDtoCopyWithImpl<$Res>
    implements $JenkinsServerInfoDtoCopyWith<$Res> {
  _$JenkinsServerInfoDtoCopyWithImpl(this._self, this._then);

  final JenkinsServerInfoDto _self;
  final $Res Function(JenkinsServerInfoDto) _then;

/// Create a copy of JenkinsServerInfoDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mode = freezed,Object? nodeDescription = freezed,Object? numExecutors = freezed,Object? useSecurity = freezed,Object? jobs = null,}) {
  return _then(_self.copyWith(
mode: freezed == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String?,nodeDescription: freezed == nodeDescription ? _self.nodeDescription : nodeDescription // ignore: cast_nullable_to_non_nullable
as String?,numExecutors: freezed == numExecutors ? _self.numExecutors : numExecutors // ignore: cast_nullable_to_non_nullable
as int?,useSecurity: freezed == useSecurity ? _self.useSecurity : useSecurity // ignore: cast_nullable_to_non_nullable
as bool?,jobs: null == jobs ? _self.jobs : jobs // ignore: cast_nullable_to_non_nullable
as List<JenkinsJobDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [JenkinsServerInfoDto].
extension JenkinsServerInfoDtoPatterns on JenkinsServerInfoDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JenkinsServerInfoDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JenkinsServerInfoDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JenkinsServerInfoDto value)  $default,){
final _that = this;
switch (_that) {
case _JenkinsServerInfoDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JenkinsServerInfoDto value)?  $default,){
final _that = this;
switch (_that) {
case _JenkinsServerInfoDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? mode,  String? nodeDescription,  int? numExecutors,  bool? useSecurity,  List<JenkinsJobDto> jobs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JenkinsServerInfoDto() when $default != null:
return $default(_that.mode,_that.nodeDescription,_that.numExecutors,_that.useSecurity,_that.jobs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? mode,  String? nodeDescription,  int? numExecutors,  bool? useSecurity,  List<JenkinsJobDto> jobs)  $default,) {final _that = this;
switch (_that) {
case _JenkinsServerInfoDto():
return $default(_that.mode,_that.nodeDescription,_that.numExecutors,_that.useSecurity,_that.jobs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? mode,  String? nodeDescription,  int? numExecutors,  bool? useSecurity,  List<JenkinsJobDto> jobs)?  $default,) {final _that = this;
switch (_that) {
case _JenkinsServerInfoDto() when $default != null:
return $default(_that.mode,_that.nodeDescription,_that.numExecutors,_that.useSecurity,_that.jobs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JenkinsServerInfoDto implements JenkinsServerInfoDto {
  const _JenkinsServerInfoDto({this.mode, this.nodeDescription, this.numExecutors, this.useSecurity, final  List<JenkinsJobDto> jobs = const []}): _jobs = jobs;
  factory _JenkinsServerInfoDto.fromJson(Map<String, dynamic> json) => _$JenkinsServerInfoDtoFromJson(json);

@override final  String? mode;
@override final  String? nodeDescription;
@override final  int? numExecutors;
@override final  bool? useSecurity;
 final  List<JenkinsJobDto> _jobs;
@override@JsonKey() List<JenkinsJobDto> get jobs {
  if (_jobs is EqualUnmodifiableListView) return _jobs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_jobs);
}


/// Create a copy of JenkinsServerInfoDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JenkinsServerInfoDtoCopyWith<_JenkinsServerInfoDto> get copyWith => __$JenkinsServerInfoDtoCopyWithImpl<_JenkinsServerInfoDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JenkinsServerInfoDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JenkinsServerInfoDto&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.nodeDescription, nodeDescription) || other.nodeDescription == nodeDescription)&&(identical(other.numExecutors, numExecutors) || other.numExecutors == numExecutors)&&(identical(other.useSecurity, useSecurity) || other.useSecurity == useSecurity)&&const DeepCollectionEquality().equals(other._jobs, _jobs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mode,nodeDescription,numExecutors,useSecurity,const DeepCollectionEquality().hash(_jobs));

@override
String toString() {
  return 'JenkinsServerInfoDto(mode: $mode, nodeDescription: $nodeDescription, numExecutors: $numExecutors, useSecurity: $useSecurity, jobs: $jobs)';
}


}

/// @nodoc
abstract mixin class _$JenkinsServerInfoDtoCopyWith<$Res> implements $JenkinsServerInfoDtoCopyWith<$Res> {
  factory _$JenkinsServerInfoDtoCopyWith(_JenkinsServerInfoDto value, $Res Function(_JenkinsServerInfoDto) _then) = __$JenkinsServerInfoDtoCopyWithImpl;
@override @useResult
$Res call({
 String? mode, String? nodeDescription, int? numExecutors, bool? useSecurity, List<JenkinsJobDto> jobs
});




}
/// @nodoc
class __$JenkinsServerInfoDtoCopyWithImpl<$Res>
    implements _$JenkinsServerInfoDtoCopyWith<$Res> {
  __$JenkinsServerInfoDtoCopyWithImpl(this._self, this._then);

  final _JenkinsServerInfoDto _self;
  final $Res Function(_JenkinsServerInfoDto) _then;

/// Create a copy of JenkinsServerInfoDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mode = freezed,Object? nodeDescription = freezed,Object? numExecutors = freezed,Object? useSecurity = freezed,Object? jobs = null,}) {
  return _then(_JenkinsServerInfoDto(
mode: freezed == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String?,nodeDescription: freezed == nodeDescription ? _self.nodeDescription : nodeDescription // ignore: cast_nullable_to_non_nullable
as String?,numExecutors: freezed == numExecutors ? _self.numExecutors : numExecutors // ignore: cast_nullable_to_non_nullable
as int?,useSecurity: freezed == useSecurity ? _self.useSecurity : useSecurity // ignore: cast_nullable_to_non_nullable
as bool?,jobs: null == jobs ? _self._jobs : jobs // ignore: cast_nullable_to_non_nullable
as List<JenkinsJobDto>,
  ));
}


}

// dart format on
