// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'github_repo_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GitHubRepoDto {

 int get id; String get name;// GitHub's JSON is snake_case (`full_name`, `default_branch`) --
// json_serializable doesn't infer this automatically per-field the
// way some generators do, so each needs an explicit @JsonKey.
@JsonKey(name: 'full_name') String get fullName; GitHubRepoOwnerDto get owner; bool get private;@JsonKey(name: 'default_branch') String get defaultBranch;
/// Create a copy of GitHubRepoDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitHubRepoDtoCopyWith<GitHubRepoDto> get copyWith => _$GitHubRepoDtoCopyWithImpl<GitHubRepoDto>(this as GitHubRepoDto, _$identity);

  /// Serializes this GitHubRepoDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitHubRepoDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.private, private) || other.private == private)&&(identical(other.defaultBranch, defaultBranch) || other.defaultBranch == defaultBranch));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,fullName,owner,private,defaultBranch);

@override
String toString() {
  return 'GitHubRepoDto(id: $id, name: $name, fullName: $fullName, owner: $owner, private: $private, defaultBranch: $defaultBranch)';
}


}

/// @nodoc
abstract mixin class $GitHubRepoDtoCopyWith<$Res>  {
  factory $GitHubRepoDtoCopyWith(GitHubRepoDto value, $Res Function(GitHubRepoDto) _then) = _$GitHubRepoDtoCopyWithImpl;
@useResult
$Res call({
 int id, String name,@JsonKey(name: 'full_name') String fullName, GitHubRepoOwnerDto owner, bool private,@JsonKey(name: 'default_branch') String defaultBranch
});


$GitHubRepoOwnerDtoCopyWith<$Res> get owner;

}
/// @nodoc
class _$GitHubRepoDtoCopyWithImpl<$Res>
    implements $GitHubRepoDtoCopyWith<$Res> {
  _$GitHubRepoDtoCopyWithImpl(this._self, this._then);

  final GitHubRepoDto _self;
  final $Res Function(GitHubRepoDto) _then;

/// Create a copy of GitHubRepoDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? fullName = null,Object? owner = null,Object? private = null,Object? defaultBranch = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as GitHubRepoOwnerDto,private: null == private ? _self.private : private // ignore: cast_nullable_to_non_nullable
as bool,defaultBranch: null == defaultBranch ? _self.defaultBranch : defaultBranch // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of GitHubRepoDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GitHubRepoOwnerDtoCopyWith<$Res> get owner {
  
  return $GitHubRepoOwnerDtoCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}


/// Adds pattern-matching-related methods to [GitHubRepoDto].
extension GitHubRepoDtoPatterns on GitHubRepoDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GitHubRepoDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GitHubRepoDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GitHubRepoDto value)  $default,){
final _that = this;
switch (_that) {
case _GitHubRepoDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GitHubRepoDto value)?  $default,){
final _that = this;
switch (_that) {
case _GitHubRepoDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'full_name')  String fullName,  GitHubRepoOwnerDto owner,  bool private, @JsonKey(name: 'default_branch')  String defaultBranch)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitHubRepoDto() when $default != null:
return $default(_that.id,_that.name,_that.fullName,_that.owner,_that.private,_that.defaultBranch);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'full_name')  String fullName,  GitHubRepoOwnerDto owner,  bool private, @JsonKey(name: 'default_branch')  String defaultBranch)  $default,) {final _that = this;
switch (_that) {
case _GitHubRepoDto():
return $default(_that.id,_that.name,_that.fullName,_that.owner,_that.private,_that.defaultBranch);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name, @JsonKey(name: 'full_name')  String fullName,  GitHubRepoOwnerDto owner,  bool private, @JsonKey(name: 'default_branch')  String defaultBranch)?  $default,) {final _that = this;
switch (_that) {
case _GitHubRepoDto() when $default != null:
return $default(_that.id,_that.name,_that.fullName,_that.owner,_that.private,_that.defaultBranch);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GitHubRepoDto implements GitHubRepoDto {
  const _GitHubRepoDto({required this.id, required this.name, @JsonKey(name: 'full_name') required this.fullName, required this.owner, this.private = false, @JsonKey(name: 'default_branch') this.defaultBranch = 'main'});
  factory _GitHubRepoDto.fromJson(Map<String, dynamic> json) => _$GitHubRepoDtoFromJson(json);

@override final  int id;
@override final  String name;
// GitHub's JSON is snake_case (`full_name`, `default_branch`) --
// json_serializable doesn't infer this automatically per-field the
// way some generators do, so each needs an explicit @JsonKey.
@override@JsonKey(name: 'full_name') final  String fullName;
@override final  GitHubRepoOwnerDto owner;
@override@JsonKey() final  bool private;
@override@JsonKey(name: 'default_branch') final  String defaultBranch;

/// Create a copy of GitHubRepoDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GitHubRepoDtoCopyWith<_GitHubRepoDto> get copyWith => __$GitHubRepoDtoCopyWithImpl<_GitHubRepoDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GitHubRepoDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitHubRepoDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.private, private) || other.private == private)&&(identical(other.defaultBranch, defaultBranch) || other.defaultBranch == defaultBranch));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,fullName,owner,private,defaultBranch);

@override
String toString() {
  return 'GitHubRepoDto(id: $id, name: $name, fullName: $fullName, owner: $owner, private: $private, defaultBranch: $defaultBranch)';
}


}

/// @nodoc
abstract mixin class _$GitHubRepoDtoCopyWith<$Res> implements $GitHubRepoDtoCopyWith<$Res> {
  factory _$GitHubRepoDtoCopyWith(_GitHubRepoDto value, $Res Function(_GitHubRepoDto) _then) = __$GitHubRepoDtoCopyWithImpl;
@override @useResult
$Res call({
 int id, String name,@JsonKey(name: 'full_name') String fullName, GitHubRepoOwnerDto owner, bool private,@JsonKey(name: 'default_branch') String defaultBranch
});


@override $GitHubRepoOwnerDtoCopyWith<$Res> get owner;

}
/// @nodoc
class __$GitHubRepoDtoCopyWithImpl<$Res>
    implements _$GitHubRepoDtoCopyWith<$Res> {
  __$GitHubRepoDtoCopyWithImpl(this._self, this._then);

  final _GitHubRepoDto _self;
  final $Res Function(_GitHubRepoDto) _then;

/// Create a copy of GitHubRepoDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? fullName = null,Object? owner = null,Object? private = null,Object? defaultBranch = null,}) {
  return _then(_GitHubRepoDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as GitHubRepoOwnerDto,private: null == private ? _self.private : private // ignore: cast_nullable_to_non_nullable
as bool,defaultBranch: null == defaultBranch ? _self.defaultBranch : defaultBranch // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of GitHubRepoDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GitHubRepoOwnerDtoCopyWith<$Res> get owner {
  
  return $GitHubRepoOwnerDtoCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}


/// @nodoc
mixin _$GitHubRepoOwnerDto {

 String get login;
/// Create a copy of GitHubRepoOwnerDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitHubRepoOwnerDtoCopyWith<GitHubRepoOwnerDto> get copyWith => _$GitHubRepoOwnerDtoCopyWithImpl<GitHubRepoOwnerDto>(this as GitHubRepoOwnerDto, _$identity);

  /// Serializes this GitHubRepoOwnerDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitHubRepoOwnerDto&&(identical(other.login, login) || other.login == login));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,login);

@override
String toString() {
  return 'GitHubRepoOwnerDto(login: $login)';
}


}

/// @nodoc
abstract mixin class $GitHubRepoOwnerDtoCopyWith<$Res>  {
  factory $GitHubRepoOwnerDtoCopyWith(GitHubRepoOwnerDto value, $Res Function(GitHubRepoOwnerDto) _then) = _$GitHubRepoOwnerDtoCopyWithImpl;
@useResult
$Res call({
 String login
});




}
/// @nodoc
class _$GitHubRepoOwnerDtoCopyWithImpl<$Res>
    implements $GitHubRepoOwnerDtoCopyWith<$Res> {
  _$GitHubRepoOwnerDtoCopyWithImpl(this._self, this._then);

  final GitHubRepoOwnerDto _self;
  final $Res Function(GitHubRepoOwnerDto) _then;

/// Create a copy of GitHubRepoOwnerDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? login = null,}) {
  return _then(_self.copyWith(
login: null == login ? _self.login : login // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GitHubRepoOwnerDto].
extension GitHubRepoOwnerDtoPatterns on GitHubRepoOwnerDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GitHubRepoOwnerDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GitHubRepoOwnerDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GitHubRepoOwnerDto value)  $default,){
final _that = this;
switch (_that) {
case _GitHubRepoOwnerDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GitHubRepoOwnerDto value)?  $default,){
final _that = this;
switch (_that) {
case _GitHubRepoOwnerDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String login)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitHubRepoOwnerDto() when $default != null:
return $default(_that.login);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String login)  $default,) {final _that = this;
switch (_that) {
case _GitHubRepoOwnerDto():
return $default(_that.login);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String login)?  $default,) {final _that = this;
switch (_that) {
case _GitHubRepoOwnerDto() when $default != null:
return $default(_that.login);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GitHubRepoOwnerDto implements GitHubRepoOwnerDto {
  const _GitHubRepoOwnerDto({required this.login});
  factory _GitHubRepoOwnerDto.fromJson(Map<String, dynamic> json) => _$GitHubRepoOwnerDtoFromJson(json);

@override final  String login;

/// Create a copy of GitHubRepoOwnerDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GitHubRepoOwnerDtoCopyWith<_GitHubRepoOwnerDto> get copyWith => __$GitHubRepoOwnerDtoCopyWithImpl<_GitHubRepoOwnerDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GitHubRepoOwnerDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitHubRepoOwnerDto&&(identical(other.login, login) || other.login == login));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,login);

@override
String toString() {
  return 'GitHubRepoOwnerDto(login: $login)';
}


}

/// @nodoc
abstract mixin class _$GitHubRepoOwnerDtoCopyWith<$Res> implements $GitHubRepoOwnerDtoCopyWith<$Res> {
  factory _$GitHubRepoOwnerDtoCopyWith(_GitHubRepoOwnerDto value, $Res Function(_GitHubRepoOwnerDto) _then) = __$GitHubRepoOwnerDtoCopyWithImpl;
@override @useResult
$Res call({
 String login
});




}
/// @nodoc
class __$GitHubRepoOwnerDtoCopyWithImpl<$Res>
    implements _$GitHubRepoOwnerDtoCopyWith<$Res> {
  __$GitHubRepoOwnerDtoCopyWithImpl(this._self, this._then);

  final _GitHubRepoOwnerDto _self;
  final $Res Function(_GitHubRepoOwnerDto) _then;

/// Create a copy of GitHubRepoOwnerDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? login = null,}) {
  return _then(_GitHubRepoOwnerDto(
login: null == login ? _self.login : login // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
