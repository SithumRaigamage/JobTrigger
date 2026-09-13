// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_info_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppInfoDto {

@JsonKey(name: '_id') String get id; String get appVersion; String get buildNumber; String? get privacyPolicyUrl; String? get termsOfServiceUrl; String? get supportEmail; String? get openSourceLicensesUrl; String? get createdAt; String? get updatedAt;
/// Create a copy of AppInfoDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppInfoDtoCopyWith<AppInfoDto> get copyWith => _$AppInfoDtoCopyWithImpl<AppInfoDto>(this as AppInfoDto, _$identity);

  /// Serializes this AppInfoDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppInfoDto&&(identical(other.id, id) || other.id == id)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&(identical(other.buildNumber, buildNumber) || other.buildNumber == buildNumber)&&(identical(other.privacyPolicyUrl, privacyPolicyUrl) || other.privacyPolicyUrl == privacyPolicyUrl)&&(identical(other.termsOfServiceUrl, termsOfServiceUrl) || other.termsOfServiceUrl == termsOfServiceUrl)&&(identical(other.supportEmail, supportEmail) || other.supportEmail == supportEmail)&&(identical(other.openSourceLicensesUrl, openSourceLicensesUrl) || other.openSourceLicensesUrl == openSourceLicensesUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,appVersion,buildNumber,privacyPolicyUrl,termsOfServiceUrl,supportEmail,openSourceLicensesUrl,createdAt,updatedAt);

@override
String toString() {
  return 'AppInfoDto(id: $id, appVersion: $appVersion, buildNumber: $buildNumber, privacyPolicyUrl: $privacyPolicyUrl, termsOfServiceUrl: $termsOfServiceUrl, supportEmail: $supportEmail, openSourceLicensesUrl: $openSourceLicensesUrl, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $AppInfoDtoCopyWith<$Res>  {
  factory $AppInfoDtoCopyWith(AppInfoDto value, $Res Function(AppInfoDto) _then) = _$AppInfoDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: '_id') String id, String appVersion, String buildNumber, String? privacyPolicyUrl, String? termsOfServiceUrl, String? supportEmail, String? openSourceLicensesUrl, String? createdAt, String? updatedAt
});




}
/// @nodoc
class _$AppInfoDtoCopyWithImpl<$Res>
    implements $AppInfoDtoCopyWith<$Res> {
  _$AppInfoDtoCopyWithImpl(this._self, this._then);

  final AppInfoDto _self;
  final $Res Function(AppInfoDto) _then;

/// Create a copy of AppInfoDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? appVersion = null,Object? buildNumber = null,Object? privacyPolicyUrl = freezed,Object? termsOfServiceUrl = freezed,Object? supportEmail = freezed,Object? openSourceLicensesUrl = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,appVersion: null == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String,buildNumber: null == buildNumber ? _self.buildNumber : buildNumber // ignore: cast_nullable_to_non_nullable
as String,privacyPolicyUrl: freezed == privacyPolicyUrl ? _self.privacyPolicyUrl : privacyPolicyUrl // ignore: cast_nullable_to_non_nullable
as String?,termsOfServiceUrl: freezed == termsOfServiceUrl ? _self.termsOfServiceUrl : termsOfServiceUrl // ignore: cast_nullable_to_non_nullable
as String?,supportEmail: freezed == supportEmail ? _self.supportEmail : supportEmail // ignore: cast_nullable_to_non_nullable
as String?,openSourceLicensesUrl: freezed == openSourceLicensesUrl ? _self.openSourceLicensesUrl : openSourceLicensesUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppInfoDto].
extension AppInfoDtoPatterns on AppInfoDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppInfoDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppInfoDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppInfoDto value)  $default,){
final _that = this;
switch (_that) {
case _AppInfoDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppInfoDto value)?  $default,){
final _that = this;
switch (_that) {
case _AppInfoDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String id,  String appVersion,  String buildNumber,  String? privacyPolicyUrl,  String? termsOfServiceUrl,  String? supportEmail,  String? openSourceLicensesUrl,  String? createdAt,  String? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppInfoDto() when $default != null:
return $default(_that.id,_that.appVersion,_that.buildNumber,_that.privacyPolicyUrl,_that.termsOfServiceUrl,_that.supportEmail,_that.openSourceLicensesUrl,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String id,  String appVersion,  String buildNumber,  String? privacyPolicyUrl,  String? termsOfServiceUrl,  String? supportEmail,  String? openSourceLicensesUrl,  String? createdAt,  String? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _AppInfoDto():
return $default(_that.id,_that.appVersion,_that.buildNumber,_that.privacyPolicyUrl,_that.termsOfServiceUrl,_that.supportEmail,_that.openSourceLicensesUrl,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: '_id')  String id,  String appVersion,  String buildNumber,  String? privacyPolicyUrl,  String? termsOfServiceUrl,  String? supportEmail,  String? openSourceLicensesUrl,  String? createdAt,  String? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _AppInfoDto() when $default != null:
return $default(_that.id,_that.appVersion,_that.buildNumber,_that.privacyPolicyUrl,_that.termsOfServiceUrl,_that.supportEmail,_that.openSourceLicensesUrl,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppInfoDto implements AppInfoDto {
  const _AppInfoDto({@JsonKey(name: '_id') required this.id, required this.appVersion, required this.buildNumber, this.privacyPolicyUrl, this.termsOfServiceUrl, this.supportEmail, this.openSourceLicensesUrl, this.createdAt, this.updatedAt});
  factory _AppInfoDto.fromJson(Map<String, dynamic> json) => _$AppInfoDtoFromJson(json);

@override@JsonKey(name: '_id') final  String id;
@override final  String appVersion;
@override final  String buildNumber;
@override final  String? privacyPolicyUrl;
@override final  String? termsOfServiceUrl;
@override final  String? supportEmail;
@override final  String? openSourceLicensesUrl;
@override final  String? createdAt;
@override final  String? updatedAt;

/// Create a copy of AppInfoDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppInfoDtoCopyWith<_AppInfoDto> get copyWith => __$AppInfoDtoCopyWithImpl<_AppInfoDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppInfoDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppInfoDto&&(identical(other.id, id) || other.id == id)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&(identical(other.buildNumber, buildNumber) || other.buildNumber == buildNumber)&&(identical(other.privacyPolicyUrl, privacyPolicyUrl) || other.privacyPolicyUrl == privacyPolicyUrl)&&(identical(other.termsOfServiceUrl, termsOfServiceUrl) || other.termsOfServiceUrl == termsOfServiceUrl)&&(identical(other.supportEmail, supportEmail) || other.supportEmail == supportEmail)&&(identical(other.openSourceLicensesUrl, openSourceLicensesUrl) || other.openSourceLicensesUrl == openSourceLicensesUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,appVersion,buildNumber,privacyPolicyUrl,termsOfServiceUrl,supportEmail,openSourceLicensesUrl,createdAt,updatedAt);

@override
String toString() {
  return 'AppInfoDto(id: $id, appVersion: $appVersion, buildNumber: $buildNumber, privacyPolicyUrl: $privacyPolicyUrl, termsOfServiceUrl: $termsOfServiceUrl, supportEmail: $supportEmail, openSourceLicensesUrl: $openSourceLicensesUrl, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$AppInfoDtoCopyWith<$Res> implements $AppInfoDtoCopyWith<$Res> {
  factory _$AppInfoDtoCopyWith(_AppInfoDto value, $Res Function(_AppInfoDto) _then) = __$AppInfoDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '_id') String id, String appVersion, String buildNumber, String? privacyPolicyUrl, String? termsOfServiceUrl, String? supportEmail, String? openSourceLicensesUrl, String? createdAt, String? updatedAt
});




}
/// @nodoc
class __$AppInfoDtoCopyWithImpl<$Res>
    implements _$AppInfoDtoCopyWith<$Res> {
  __$AppInfoDtoCopyWithImpl(this._self, this._then);

  final _AppInfoDto _self;
  final $Res Function(_AppInfoDto) _then;

/// Create a copy of AppInfoDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? appVersion = null,Object? buildNumber = null,Object? privacyPolicyUrl = freezed,Object? termsOfServiceUrl = freezed,Object? supportEmail = freezed,Object? openSourceLicensesUrl = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_AppInfoDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,appVersion: null == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String,buildNumber: null == buildNumber ? _self.buildNumber : buildNumber // ignore: cast_nullable_to_non_nullable
as String,privacyPolicyUrl: freezed == privacyPolicyUrl ? _self.privacyPolicyUrl : privacyPolicyUrl // ignore: cast_nullable_to_non_nullable
as String?,termsOfServiceUrl: freezed == termsOfServiceUrl ? _self.termsOfServiceUrl : termsOfServiceUrl // ignore: cast_nullable_to_non_nullable
as String?,supportEmail: freezed == supportEmail ? _self.supportEmail : supportEmail // ignore: cast_nullable_to_non_nullable
as String?,openSourceLicensesUrl: freezed == openSourceLicensesUrl ? _self.openSourceLicensesUrl : openSourceLicensesUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
