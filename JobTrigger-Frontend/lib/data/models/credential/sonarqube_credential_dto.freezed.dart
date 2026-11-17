// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sonarqube_credential_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SonarQubeCredentialDto {

@JsonKey(name: '_id') String get id; String get label; String get baseUrl;/// Null when the backend could not decrypt the stored token (AUD-63)
/// — the credential is still listed, but it can't be used until the
/// user types the token again.
 String? get token;/// E4: the backend's lists carry a mask and no token. `CredentialSecrets`
/// fills [token] before `toDomain`.
 String? get secretMask; String? get defaultOrganization; bool get isDefault;/// AUD-63: the backend flags a credential whose token it could not
/// decrypt. Always present in the response.
 bool get needsReentry;/// P20-25: beyond the user's plan after a downgrade (absent on older
/// backends, so false).
 bool get locked; String? get createdAt; String? get updatedAt;
/// Create a copy of SonarQubeCredentialDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SonarQubeCredentialDtoCopyWith<SonarQubeCredentialDto> get copyWith => _$SonarQubeCredentialDtoCopyWithImpl<SonarQubeCredentialDto>(this as SonarQubeCredentialDto, _$identity);

  /// Serializes this SonarQubeCredentialDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SonarQubeCredentialDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SonarQubeCredentialDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.baseUrl, _this.baseUrl) || other.baseUrl == _this.baseUrl)&&(identical(other.token, _this.token) || other.token == _this.token)&&(identical(other.secretMask, _this.secretMask) || other.secretMask == _this.secretMask)&&(identical(other.defaultOrganization, _this.defaultOrganization) || other.defaultOrganization == _this.defaultOrganization)&&(identical(other.isDefault, _this.isDefault) || other.isDefault == _this.isDefault)&&(identical(other.needsReentry, _this.needsReentry) || other.needsReentry == _this.needsReentry)&&(identical(other.locked, _this.locked) || other.locked == _this.locked)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SonarQubeCredentialDto;
  return Object.hash(runtimeType,_this.id,_this.label,_this.baseUrl,_this.token,_this.secretMask,_this.defaultOrganization,_this.isDefault,_this.needsReentry,_this.locked,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as SonarQubeCredentialDto;
  return 'SonarQubeCredentialDto(id: ${_this.id}, label: ${_this.label}, baseUrl: ${_this.baseUrl}, token: ${_this.token}, secretMask: ${_this.secretMask}, defaultOrganization: ${_this.defaultOrganization}, isDefault: ${_this.isDefault}, needsReentry: ${_this.needsReentry}, locked: ${_this.locked}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $SonarQubeCredentialDtoCopyWith<$Res>  {
  factory $SonarQubeCredentialDtoCopyWith(SonarQubeCredentialDto value, $Res Function(SonarQubeCredentialDto) _then) = _$SonarQubeCredentialDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: '_id') String id, String label, String baseUrl, String? token, String? secretMask, String? defaultOrganization, bool isDefault, bool needsReentry, bool locked, String? createdAt, String? updatedAt
});




}
/// @nodoc
class _$SonarQubeCredentialDtoCopyWithImpl<$Res>
    implements $SonarQubeCredentialDtoCopyWith<$Res> {
  _$SonarQubeCredentialDtoCopyWithImpl(this._self, this._then);

  final SonarQubeCredentialDto _self;
  final $Res Function(SonarQubeCredentialDto) _then;

/// Create a copy of SonarQubeCredentialDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? baseUrl = null,Object? token = freezed,Object? secretMask = freezed,Object? defaultOrganization = freezed,Object? isDefault = null,Object? needsReentry = null,Object? locked = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(SonarQubeCredentialDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String,token: freezed == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String?,secretMask: freezed == secretMask ? _self.secretMask : secretMask // ignore: cast_nullable_to_non_nullable
as String?,defaultOrganization: freezed == defaultOrganization ? _self.defaultOrganization : defaultOrganization // ignore: cast_nullable_to_non_nullable
as String?,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,needsReentry: null == needsReentry ? _self.needsReentry : needsReentry // ignore: cast_nullable_to_non_nullable
as bool,locked: null == locked ? _self.locked : locked // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SonarQubeCredentialDto].
extension SonarQubeCredentialDtoPatterns on SonarQubeCredentialDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SonarQubeCredentialDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SonarQubeCredentialDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SonarQubeCredentialDto value)  $default,){
final _that = this;
switch (_that) {
case _SonarQubeCredentialDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SonarQubeCredentialDto value)?  $default,){
final _that = this;
switch (_that) {
case _SonarQubeCredentialDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String id,  String label,  String baseUrl,  String? token,  String? secretMask,  String? defaultOrganization,  bool isDefault,  bool needsReentry,  bool locked,  String? createdAt,  String? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SonarQubeCredentialDto() when $default != null:
return $default(_that.id,_that.label,_that.baseUrl,_that.token,_that.secretMask,_that.defaultOrganization,_that.isDefault,_that.needsReentry,_that.locked,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String id,  String label,  String baseUrl,  String? token,  String? secretMask,  String? defaultOrganization,  bool isDefault,  bool needsReentry,  bool locked,  String? createdAt,  String? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _SonarQubeCredentialDto():
return $default(_that.id,_that.label,_that.baseUrl,_that.token,_that.secretMask,_that.defaultOrganization,_that.isDefault,_that.needsReentry,_that.locked,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: '_id')  String id,  String label,  String baseUrl,  String? token,  String? secretMask,  String? defaultOrganization,  bool isDefault,  bool needsReentry,  bool locked,  String? createdAt,  String? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _SonarQubeCredentialDto() when $default != null:
return $default(_that.id,_that.label,_that.baseUrl,_that.token,_that.secretMask,_that.defaultOrganization,_that.isDefault,_that.needsReentry,_that.locked,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SonarQubeCredentialDto implements SonarQubeCredentialDto {
  const _SonarQubeCredentialDto({@JsonKey(name: '_id') required this.id, required this.label, required this.baseUrl, this.token, this.secretMask, this.defaultOrganization, this.isDefault = false, this.needsReentry = false, this.locked = false, this.createdAt, this.updatedAt});
  factory _SonarQubeCredentialDto.fromJson(Map<String, dynamic> json) => _$SonarQubeCredentialDtoFromJson(json);

@override@JsonKey(name: '_id') final  String id;
@override final  String label;
@override final  String baseUrl;
/// Null when the backend could not decrypt the stored token (AUD-63)
/// — the credential is still listed, but it can't be used until the
/// user types the token again.
@override final  String? token;
/// E4: the backend's lists carry a mask and no token. `CredentialSecrets`
/// fills [token] before `toDomain`.
@override final  String? secretMask;
@override final  String? defaultOrganization;
@override@JsonKey() final  bool isDefault;
/// AUD-63: the backend flags a credential whose token it could not
/// decrypt. Always present in the response.
@override@JsonKey() final  bool needsReentry;
/// P20-25: beyond the user's plan after a downgrade (absent on older
/// backends, so false).
@override@JsonKey() final  bool locked;
@override final  String? createdAt;
@override final  String? updatedAt;

/// Create a copy of SonarQubeCredentialDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SonarQubeCredentialDtoCopyWith<_SonarQubeCredentialDto> get copyWith => __$SonarQubeCredentialDtoCopyWithImpl<_SonarQubeCredentialDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SonarQubeCredentialDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SonarQubeCredentialDto&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl)&&(identical(other.token, token) || other.token == token)&&(identical(other.secretMask, secretMask) || other.secretMask == secretMask)&&(identical(other.defaultOrganization, defaultOrganization) || other.defaultOrganization == defaultOrganization)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.needsReentry, needsReentry) || other.needsReentry == needsReentry)&&(identical(other.locked, locked) || other.locked == locked)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,label,baseUrl,token,secretMask,defaultOrganization,isDefault,needsReentry,locked,createdAt,updatedAt);
}

@override
String toString() {
    return 'SonarQubeCredentialDto(id: $id, label: $label, baseUrl: $baseUrl, token: $token, secretMask: $secretMask, defaultOrganization: $defaultOrganization, isDefault: $isDefault, needsReentry: $needsReentry, locked: $locked, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SonarQubeCredentialDtoCopyWith<$Res> implements $SonarQubeCredentialDtoCopyWith<$Res> {
  factory _$SonarQubeCredentialDtoCopyWith(_SonarQubeCredentialDto value, $Res Function(_SonarQubeCredentialDto) _then) = __$SonarQubeCredentialDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '_id') String id, String label, String baseUrl, String? token, String? secretMask, String? defaultOrganization, bool isDefault, bool needsReentry, bool locked, String? createdAt, String? updatedAt
});




}
/// @nodoc
class __$SonarQubeCredentialDtoCopyWithImpl<$Res>
    implements _$SonarQubeCredentialDtoCopyWith<$Res> {
  __$SonarQubeCredentialDtoCopyWithImpl(this._self, this._then);

  final _SonarQubeCredentialDto _self;
  final $Res Function(_SonarQubeCredentialDto) _then;

/// Create a copy of SonarQubeCredentialDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? baseUrl = null,Object? token = freezed,Object? secretMask = freezed,Object? defaultOrganization = freezed,Object? isDefault = null,Object? needsReentry = null,Object? locked = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_SonarQubeCredentialDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String,token: freezed == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String?,secretMask: freezed == secretMask ? _self.secretMask : secretMask // ignore: cast_nullable_to_non_nullable
as String?,defaultOrganization: freezed == defaultOrganization ? _self.defaultOrganization : defaultOrganization // ignore: cast_nullable_to_non_nullable
as String?,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,needsReentry: null == needsReentry ? _self.needsReentry : needsReentry // ignore: cast_nullable_to_non_nullable
as bool,locked: null == locked ? _self.locked : locked // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
