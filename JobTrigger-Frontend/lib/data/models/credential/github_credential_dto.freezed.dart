// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'github_credential_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GitHubCredentialDto {

@JsonKey(name: '_id') String get id; String get label; String get token; String? get defaultOwner; bool get isDefault; String? get createdAt; String? get updatedAt;
/// Create a copy of GitHubCredentialDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitHubCredentialDtoCopyWith<GitHubCredentialDto> get copyWith => _$GitHubCredentialDtoCopyWithImpl<GitHubCredentialDto>(this as GitHubCredentialDto, _$identity);

  /// Serializes this GitHubCredentialDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitHubCredentialDto&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.token, token) || other.token == token)&&(identical(other.defaultOwner, defaultOwner) || other.defaultOwner == defaultOwner)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,token,defaultOwner,isDefault,createdAt,updatedAt);

@override
String toString() {
  return 'GitHubCredentialDto(id: $id, label: $label, token: $token, defaultOwner: $defaultOwner, isDefault: $isDefault, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $GitHubCredentialDtoCopyWith<$Res>  {
  factory $GitHubCredentialDtoCopyWith(GitHubCredentialDto value, $Res Function(GitHubCredentialDto) _then) = _$GitHubCredentialDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: '_id') String id, String label, String token, String? defaultOwner, bool isDefault, String? createdAt, String? updatedAt
});




}
/// @nodoc
class _$GitHubCredentialDtoCopyWithImpl<$Res>
    implements $GitHubCredentialDtoCopyWith<$Res> {
  _$GitHubCredentialDtoCopyWithImpl(this._self, this._then);

  final GitHubCredentialDto _self;
  final $Res Function(GitHubCredentialDto) _then;

/// Create a copy of GitHubCredentialDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? token = null,Object? defaultOwner = freezed,Object? isDefault = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,defaultOwner: freezed == defaultOwner ? _self.defaultOwner : defaultOwner // ignore: cast_nullable_to_non_nullable
as String?,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GitHubCredentialDto].
extension GitHubCredentialDtoPatterns on GitHubCredentialDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GitHubCredentialDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GitHubCredentialDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GitHubCredentialDto value)  $default,){
final _that = this;
switch (_that) {
case _GitHubCredentialDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GitHubCredentialDto value)?  $default,){
final _that = this;
switch (_that) {
case _GitHubCredentialDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String id,  String label,  String token,  String? defaultOwner,  bool isDefault,  String? createdAt,  String? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitHubCredentialDto() when $default != null:
return $default(_that.id,_that.label,_that.token,_that.defaultOwner,_that.isDefault,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String id,  String label,  String token,  String? defaultOwner,  bool isDefault,  String? createdAt,  String? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _GitHubCredentialDto():
return $default(_that.id,_that.label,_that.token,_that.defaultOwner,_that.isDefault,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: '_id')  String id,  String label,  String token,  String? defaultOwner,  bool isDefault,  String? createdAt,  String? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _GitHubCredentialDto() when $default != null:
return $default(_that.id,_that.label,_that.token,_that.defaultOwner,_that.isDefault,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GitHubCredentialDto implements GitHubCredentialDto {
  const _GitHubCredentialDto({@JsonKey(name: '_id') required this.id, required this.label, required this.token, this.defaultOwner, this.isDefault = false, this.createdAt, this.updatedAt});
  factory _GitHubCredentialDto.fromJson(Map<String, dynamic> json) => _$GitHubCredentialDtoFromJson(json);

@override@JsonKey(name: '_id') final  String id;
@override final  String label;
@override final  String token;
@override final  String? defaultOwner;
@override@JsonKey() final  bool isDefault;
@override final  String? createdAt;
@override final  String? updatedAt;

/// Create a copy of GitHubCredentialDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GitHubCredentialDtoCopyWith<_GitHubCredentialDto> get copyWith => __$GitHubCredentialDtoCopyWithImpl<_GitHubCredentialDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GitHubCredentialDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitHubCredentialDto&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.token, token) || other.token == token)&&(identical(other.defaultOwner, defaultOwner) || other.defaultOwner == defaultOwner)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,token,defaultOwner,isDefault,createdAt,updatedAt);

@override
String toString() {
  return 'GitHubCredentialDto(id: $id, label: $label, token: $token, defaultOwner: $defaultOwner, isDefault: $isDefault, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$GitHubCredentialDtoCopyWith<$Res> implements $GitHubCredentialDtoCopyWith<$Res> {
  factory _$GitHubCredentialDtoCopyWith(_GitHubCredentialDto value, $Res Function(_GitHubCredentialDto) _then) = __$GitHubCredentialDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '_id') String id, String label, String token, String? defaultOwner, bool isDefault, String? createdAt, String? updatedAt
});




}
/// @nodoc
class __$GitHubCredentialDtoCopyWithImpl<$Res>
    implements _$GitHubCredentialDtoCopyWith<$Res> {
  __$GitHubCredentialDtoCopyWithImpl(this._self, this._then);

  final _GitHubCredentialDto _self;
  final $Res Function(_GitHubCredentialDto) _then;

/// Create a copy of GitHubCredentialDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? token = null,Object? defaultOwner = freezed,Object? isDefault = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_GitHubCredentialDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,defaultOwner: freezed == defaultOwner ? _self.defaultOwner : defaultOwner // ignore: cast_nullable_to_non_nullable
as String?,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
