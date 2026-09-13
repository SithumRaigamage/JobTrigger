// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'credential_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CredentialDto {

@JsonKey(name: '_id') String get id; String get serverName; String get jenkinsURL; String get username; String get password; String? get paramToken; bool get isDefault; String? get createdAt; String? get updatedAt;
/// Create a copy of CredentialDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CredentialDtoCopyWith<CredentialDto> get copyWith => _$CredentialDtoCopyWithImpl<CredentialDto>(this as CredentialDto, _$identity);

  /// Serializes this CredentialDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CredentialDto&&(identical(other.id, id) || other.id == id)&&(identical(other.serverName, serverName) || other.serverName == serverName)&&(identical(other.jenkinsURL, jenkinsURL) || other.jenkinsURL == jenkinsURL)&&(identical(other.username, username) || other.username == username)&&(identical(other.password, password) || other.password == password)&&(identical(other.paramToken, paramToken) || other.paramToken == paramToken)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,serverName,jenkinsURL,username,password,paramToken,isDefault,createdAt,updatedAt);

@override
String toString() {
  return 'CredentialDto(id: $id, serverName: $serverName, jenkinsURL: $jenkinsURL, username: $username, password: $password, paramToken: $paramToken, isDefault: $isDefault, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $CredentialDtoCopyWith<$Res>  {
  factory $CredentialDtoCopyWith(CredentialDto value, $Res Function(CredentialDto) _then) = _$CredentialDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: '_id') String id, String serverName, String jenkinsURL, String username, String password, String? paramToken, bool isDefault, String? createdAt, String? updatedAt
});




}
/// @nodoc
class _$CredentialDtoCopyWithImpl<$Res>
    implements $CredentialDtoCopyWith<$Res> {
  _$CredentialDtoCopyWithImpl(this._self, this._then);

  final CredentialDto _self;
  final $Res Function(CredentialDto) _then;

/// Create a copy of CredentialDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? serverName = null,Object? jenkinsURL = null,Object? username = null,Object? password = null,Object? paramToken = freezed,Object? isDefault = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,serverName: null == serverName ? _self.serverName : serverName // ignore: cast_nullable_to_non_nullable
as String,jenkinsURL: null == jenkinsURL ? _self.jenkinsURL : jenkinsURL // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,paramToken: freezed == paramToken ? _self.paramToken : paramToken // ignore: cast_nullable_to_non_nullable
as String?,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CredentialDto].
extension CredentialDtoPatterns on CredentialDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CredentialDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CredentialDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CredentialDto value)  $default,){
final _that = this;
switch (_that) {
case _CredentialDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CredentialDto value)?  $default,){
final _that = this;
switch (_that) {
case _CredentialDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String id,  String serverName,  String jenkinsURL,  String username,  String password,  String? paramToken,  bool isDefault,  String? createdAt,  String? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CredentialDto() when $default != null:
return $default(_that.id,_that.serverName,_that.jenkinsURL,_that.username,_that.password,_that.paramToken,_that.isDefault,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String id,  String serverName,  String jenkinsURL,  String username,  String password,  String? paramToken,  bool isDefault,  String? createdAt,  String? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _CredentialDto():
return $default(_that.id,_that.serverName,_that.jenkinsURL,_that.username,_that.password,_that.paramToken,_that.isDefault,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: '_id')  String id,  String serverName,  String jenkinsURL,  String username,  String password,  String? paramToken,  bool isDefault,  String? createdAt,  String? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _CredentialDto() when $default != null:
return $default(_that.id,_that.serverName,_that.jenkinsURL,_that.username,_that.password,_that.paramToken,_that.isDefault,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CredentialDto implements CredentialDto {
  const _CredentialDto({@JsonKey(name: '_id') required this.id, required this.serverName, required this.jenkinsURL, required this.username, required this.password, this.paramToken, this.isDefault = false, this.createdAt, this.updatedAt});
  factory _CredentialDto.fromJson(Map<String, dynamic> json) => _$CredentialDtoFromJson(json);

@override@JsonKey(name: '_id') final  String id;
@override final  String serverName;
@override final  String jenkinsURL;
@override final  String username;
@override final  String password;
@override final  String? paramToken;
@override@JsonKey() final  bool isDefault;
@override final  String? createdAt;
@override final  String? updatedAt;

/// Create a copy of CredentialDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CredentialDtoCopyWith<_CredentialDto> get copyWith => __$CredentialDtoCopyWithImpl<_CredentialDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CredentialDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CredentialDto&&(identical(other.id, id) || other.id == id)&&(identical(other.serverName, serverName) || other.serverName == serverName)&&(identical(other.jenkinsURL, jenkinsURL) || other.jenkinsURL == jenkinsURL)&&(identical(other.username, username) || other.username == username)&&(identical(other.password, password) || other.password == password)&&(identical(other.paramToken, paramToken) || other.paramToken == paramToken)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,serverName,jenkinsURL,username,password,paramToken,isDefault,createdAt,updatedAt);

@override
String toString() {
  return 'CredentialDto(id: $id, serverName: $serverName, jenkinsURL: $jenkinsURL, username: $username, password: $password, paramToken: $paramToken, isDefault: $isDefault, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$CredentialDtoCopyWith<$Res> implements $CredentialDtoCopyWith<$Res> {
  factory _$CredentialDtoCopyWith(_CredentialDto value, $Res Function(_CredentialDto) _then) = __$CredentialDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '_id') String id, String serverName, String jenkinsURL, String username, String password, String? paramToken, bool isDefault, String? createdAt, String? updatedAt
});




}
/// @nodoc
class __$CredentialDtoCopyWithImpl<$Res>
    implements _$CredentialDtoCopyWith<$Res> {
  __$CredentialDtoCopyWithImpl(this._self, this._then);

  final _CredentialDto _self;
  final $Res Function(_CredentialDto) _then;

/// Create a copy of CredentialDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? serverName = null,Object? jenkinsURL = null,Object? username = null,Object? password = null,Object? paramToken = freezed,Object? isDefault = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_CredentialDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,serverName: null == serverName ? _self.serverName : serverName // ignore: cast_nullable_to_non_nullable
as String,jenkinsURL: null == jenkinsURL ? _self.jenkinsURL : jenkinsURL // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,paramToken: freezed == paramToken ? _self.paramToken : paramToken // ignore: cast_nullable_to_non_nullable
as String?,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
