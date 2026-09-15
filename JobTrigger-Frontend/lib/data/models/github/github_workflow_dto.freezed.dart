// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'github_workflow_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GitHubWorkflowDto {

 int get id; String get name; String get path; String get state;
/// Create a copy of GitHubWorkflowDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitHubWorkflowDtoCopyWith<GitHubWorkflowDto> get copyWith => _$GitHubWorkflowDtoCopyWithImpl<GitHubWorkflowDto>(this as GitHubWorkflowDto, _$identity);

  /// Serializes this GitHubWorkflowDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitHubWorkflowDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.state, state) || other.state == state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,path,state);

@override
String toString() {
  return 'GitHubWorkflowDto(id: $id, name: $name, path: $path, state: $state)';
}


}

/// @nodoc
abstract mixin class $GitHubWorkflowDtoCopyWith<$Res>  {
  factory $GitHubWorkflowDtoCopyWith(GitHubWorkflowDto value, $Res Function(GitHubWorkflowDto) _then) = _$GitHubWorkflowDtoCopyWithImpl;
@useResult
$Res call({
 int id, String name, String path, String state
});




}
/// @nodoc
class _$GitHubWorkflowDtoCopyWithImpl<$Res>
    implements $GitHubWorkflowDtoCopyWith<$Res> {
  _$GitHubWorkflowDtoCopyWithImpl(this._self, this._then);

  final GitHubWorkflowDto _self;
  final $Res Function(GitHubWorkflowDto) _then;

/// Create a copy of GitHubWorkflowDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? path = null,Object? state = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GitHubWorkflowDto].
extension GitHubWorkflowDtoPatterns on GitHubWorkflowDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GitHubWorkflowDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GitHubWorkflowDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GitHubWorkflowDto value)  $default,){
final _that = this;
switch (_that) {
case _GitHubWorkflowDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GitHubWorkflowDto value)?  $default,){
final _that = this;
switch (_that) {
case _GitHubWorkflowDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String path,  String state)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitHubWorkflowDto() when $default != null:
return $default(_that.id,_that.name,_that.path,_that.state);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String path,  String state)  $default,) {final _that = this;
switch (_that) {
case _GitHubWorkflowDto():
return $default(_that.id,_that.name,_that.path,_that.state);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String path,  String state)?  $default,) {final _that = this;
switch (_that) {
case _GitHubWorkflowDto() when $default != null:
return $default(_that.id,_that.name,_that.path,_that.state);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GitHubWorkflowDto implements GitHubWorkflowDto {
  const _GitHubWorkflowDto({required this.id, required this.name, required this.path, required this.state});
  factory _GitHubWorkflowDto.fromJson(Map<String, dynamic> json) => _$GitHubWorkflowDtoFromJson(json);

@override final  int id;
@override final  String name;
@override final  String path;
@override final  String state;

/// Create a copy of GitHubWorkflowDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GitHubWorkflowDtoCopyWith<_GitHubWorkflowDto> get copyWith => __$GitHubWorkflowDtoCopyWithImpl<_GitHubWorkflowDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GitHubWorkflowDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitHubWorkflowDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.state, state) || other.state == state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,path,state);

@override
String toString() {
  return 'GitHubWorkflowDto(id: $id, name: $name, path: $path, state: $state)';
}


}

/// @nodoc
abstract mixin class _$GitHubWorkflowDtoCopyWith<$Res> implements $GitHubWorkflowDtoCopyWith<$Res> {
  factory _$GitHubWorkflowDtoCopyWith(_GitHubWorkflowDto value, $Res Function(_GitHubWorkflowDto) _then) = __$GitHubWorkflowDtoCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String path, String state
});




}
/// @nodoc
class __$GitHubWorkflowDtoCopyWithImpl<$Res>
    implements _$GitHubWorkflowDtoCopyWith<$Res> {
  __$GitHubWorkflowDtoCopyWithImpl(this._self, this._then);

  final _GitHubWorkflowDto _self;
  final $Res Function(_GitHubWorkflowDto) _then;

/// Create a copy of GitHubWorkflowDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? path = null,Object? state = null,}) {
  return _then(_GitHubWorkflowDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
