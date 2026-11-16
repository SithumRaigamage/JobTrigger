// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'student_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StudentApplicationDto {

 String get status; String? get method; String? get universityEmail; String? get rejectionReason; String? get approvedAt; String? get expiresAt;
/// Create a copy of StudentApplicationDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudentApplicationDtoCopyWith<StudentApplicationDto> get copyWith => _$StudentApplicationDtoCopyWithImpl<StudentApplicationDto>(this as StudentApplicationDto, _$identity);

  /// Serializes this StudentApplicationDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as StudentApplicationDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudentApplicationDto&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.method, _this.method) || other.method == _this.method)&&(identical(other.universityEmail, _this.universityEmail) || other.universityEmail == _this.universityEmail)&&(identical(other.rejectionReason, _this.rejectionReason) || other.rejectionReason == _this.rejectionReason)&&(identical(other.approvedAt, _this.approvedAt) || other.approvedAt == _this.approvedAt)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as StudentApplicationDto;
  return Object.hash(runtimeType,_this.status,_this.method,_this.universityEmail,_this.rejectionReason,_this.approvedAt,_this.expiresAt);
}

@override
String toString() {
  final _this = this as StudentApplicationDto;
  return 'StudentApplicationDto(status: ${_this.status}, method: ${_this.method}, universityEmail: ${_this.universityEmail}, rejectionReason: ${_this.rejectionReason}, approvedAt: ${_this.approvedAt}, expiresAt: ${_this.expiresAt})';
}


}

/// @nodoc
abstract mixin class $StudentApplicationDtoCopyWith<$Res>  {
  factory $StudentApplicationDtoCopyWith(StudentApplicationDto value, $Res Function(StudentApplicationDto) _then) = _$StudentApplicationDtoCopyWithImpl;
@useResult
$Res call({
 String status, String? method, String? universityEmail, String? rejectionReason, String? approvedAt, String? expiresAt
});




}
/// @nodoc
class _$StudentApplicationDtoCopyWithImpl<$Res>
    implements $StudentApplicationDtoCopyWith<$Res> {
  _$StudentApplicationDtoCopyWithImpl(this._self, this._then);

  final StudentApplicationDto _self;
  final $Res Function(StudentApplicationDto) _then;

/// Create a copy of StudentApplicationDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? method = freezed,Object? universityEmail = freezed,Object? rejectionReason = freezed,Object? approvedAt = freezed,Object? expiresAt = freezed,}) {
  return _then(StudentApplicationDto(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,method: freezed == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String?,universityEmail: freezed == universityEmail ? _self.universityEmail : universityEmail // ignore: cast_nullable_to_non_nullable
as String?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,approvedAt: freezed == approvedAt ? _self.approvedAt : approvedAt // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [StudentApplicationDto].
extension StudentApplicationDtoPatterns on StudentApplicationDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudentApplicationDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudentApplicationDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudentApplicationDto value)  $default,){
final _that = this;
switch (_that) {
case _StudentApplicationDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudentApplicationDto value)?  $default,){
final _that = this;
switch (_that) {
case _StudentApplicationDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  String? method,  String? universityEmail,  String? rejectionReason,  String? approvedAt,  String? expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudentApplicationDto() when $default != null:
return $default(_that.status,_that.method,_that.universityEmail,_that.rejectionReason,_that.approvedAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  String? method,  String? universityEmail,  String? rejectionReason,  String? approvedAt,  String? expiresAt)  $default,) {final _that = this;
switch (_that) {
case _StudentApplicationDto():
return $default(_that.status,_that.method,_that.universityEmail,_that.rejectionReason,_that.approvedAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  String? method,  String? universityEmail,  String? rejectionReason,  String? approvedAt,  String? expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _StudentApplicationDto() when $default != null:
return $default(_that.status,_that.method,_that.universityEmail,_that.rejectionReason,_that.approvedAt,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StudentApplicationDto implements StudentApplicationDto {
  const _StudentApplicationDto({required this.status, this.method, this.universityEmail, this.rejectionReason, this.approvedAt, this.expiresAt});
  factory _StudentApplicationDto.fromJson(Map<String, dynamic> json) => _$StudentApplicationDtoFromJson(json);

@override final  String status;
@override final  String? method;
@override final  String? universityEmail;
@override final  String? rejectionReason;
@override final  String? approvedAt;
@override final  String? expiresAt;

/// Create a copy of StudentApplicationDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudentApplicationDtoCopyWith<_StudentApplicationDto> get copyWith => __$StudentApplicationDtoCopyWithImpl<_StudentApplicationDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StudentApplicationDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudentApplicationDto&&(identical(other.status, status) || other.status == status)&&(identical(other.method, method) || other.method == method)&&(identical(other.universityEmail, universityEmail) || other.universityEmail == universityEmail)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.approvedAt, approvedAt) || other.approvedAt == approvedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,status,method,universityEmail,rejectionReason,approvedAt,expiresAt);
}

@override
String toString() {
    return 'StudentApplicationDto(status: $status, method: $method, universityEmail: $universityEmail, rejectionReason: $rejectionReason, approvedAt: $approvedAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$StudentApplicationDtoCopyWith<$Res> implements $StudentApplicationDtoCopyWith<$Res> {
  factory _$StudentApplicationDtoCopyWith(_StudentApplicationDto value, $Res Function(_StudentApplicationDto) _then) = __$StudentApplicationDtoCopyWithImpl;
@override @useResult
$Res call({
 String status, String? method, String? universityEmail, String? rejectionReason, String? approvedAt, String? expiresAt
});




}
/// @nodoc
class __$StudentApplicationDtoCopyWithImpl<$Res>
    implements _$StudentApplicationDtoCopyWith<$Res> {
  __$StudentApplicationDtoCopyWithImpl(this._self, this._then);

  final _StudentApplicationDto _self;
  final $Res Function(_StudentApplicationDto) _then;

/// Create a copy of StudentApplicationDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? method = freezed,Object? universityEmail = freezed,Object? rejectionReason = freezed,Object? approvedAt = freezed,Object? expiresAt = freezed,}) {
  return _then(_StudentApplicationDto(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,method: freezed == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String?,universityEmail: freezed == universityEmail ? _self.universityEmail : universityEmail // ignore: cast_nullable_to_non_nullable
as String?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,approvedAt: freezed == approvedAt ? _self.approvedAt : approvedAt // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
