// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_student_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AdminStudentDto {

 String get id; String get method; String get status; String get submittedAt; String? get accountEmail; String? get fullName; String? get universityEmail; String? get emailVerifiedAt; String? get reviewedAt; String? get reviewedByEmail; String? get approvedAt; String? get expiresAt; String? get rejectionReason; String? get documentMime; bool get hasDocument; bool get documentDeleted;
/// Create a copy of AdminStudentDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminStudentDtoCopyWith<AdminStudentDto> get copyWith => _$AdminStudentDtoCopyWithImpl<AdminStudentDto>(this as AdminStudentDto, _$identity);

  /// Serializes this AdminStudentDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AdminStudentDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminStudentDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.method, _this.method) || other.method == _this.method)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.submittedAt, _this.submittedAt) || other.submittedAt == _this.submittedAt)&&(identical(other.accountEmail, _this.accountEmail) || other.accountEmail == _this.accountEmail)&&(identical(other.fullName, _this.fullName) || other.fullName == _this.fullName)&&(identical(other.universityEmail, _this.universityEmail) || other.universityEmail == _this.universityEmail)&&(identical(other.emailVerifiedAt, _this.emailVerifiedAt) || other.emailVerifiedAt == _this.emailVerifiedAt)&&(identical(other.reviewedAt, _this.reviewedAt) || other.reviewedAt == _this.reviewedAt)&&(identical(other.reviewedByEmail, _this.reviewedByEmail) || other.reviewedByEmail == _this.reviewedByEmail)&&(identical(other.approvedAt, _this.approvedAt) || other.approvedAt == _this.approvedAt)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.rejectionReason, _this.rejectionReason) || other.rejectionReason == _this.rejectionReason)&&(identical(other.documentMime, _this.documentMime) || other.documentMime == _this.documentMime)&&(identical(other.hasDocument, _this.hasDocument) || other.hasDocument == _this.hasDocument)&&(identical(other.documentDeleted, _this.documentDeleted) || other.documentDeleted == _this.documentDeleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AdminStudentDto;
  return Object.hash(runtimeType,_this.id,_this.method,_this.status,_this.submittedAt,_this.accountEmail,_this.fullName,_this.universityEmail,_this.emailVerifiedAt,_this.reviewedAt,_this.reviewedByEmail,_this.approvedAt,_this.expiresAt,_this.rejectionReason,_this.documentMime,_this.hasDocument,_this.documentDeleted);
}

@override
String toString() {
  final _this = this as AdminStudentDto;
  return 'AdminStudentDto(id: ${_this.id}, method: ${_this.method}, status: ${_this.status}, submittedAt: ${_this.submittedAt}, accountEmail: ${_this.accountEmail}, fullName: ${_this.fullName}, universityEmail: ${_this.universityEmail}, emailVerifiedAt: ${_this.emailVerifiedAt}, reviewedAt: ${_this.reviewedAt}, reviewedByEmail: ${_this.reviewedByEmail}, approvedAt: ${_this.approvedAt}, expiresAt: ${_this.expiresAt}, rejectionReason: ${_this.rejectionReason}, documentMime: ${_this.documentMime}, hasDocument: ${_this.hasDocument}, documentDeleted: ${_this.documentDeleted})';
}


}

/// @nodoc
abstract mixin class $AdminStudentDtoCopyWith<$Res>  {
  factory $AdminStudentDtoCopyWith(AdminStudentDto value, $Res Function(AdminStudentDto) _then) = _$AdminStudentDtoCopyWithImpl;
@useResult
$Res call({
 String id, String method, String status, String submittedAt, String? accountEmail, String? fullName, String? universityEmail, String? emailVerifiedAt, String? reviewedAt, String? reviewedByEmail, String? approvedAt, String? expiresAt, String? rejectionReason, String? documentMime, bool hasDocument, bool documentDeleted
});




}
/// @nodoc
class _$AdminStudentDtoCopyWithImpl<$Res>
    implements $AdminStudentDtoCopyWith<$Res> {
  _$AdminStudentDtoCopyWithImpl(this._self, this._then);

  final AdminStudentDto _self;
  final $Res Function(AdminStudentDto) _then;

/// Create a copy of AdminStudentDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? method = null,Object? status = null,Object? submittedAt = null,Object? accountEmail = freezed,Object? fullName = freezed,Object? universityEmail = freezed,Object? emailVerifiedAt = freezed,Object? reviewedAt = freezed,Object? reviewedByEmail = freezed,Object? approvedAt = freezed,Object? expiresAt = freezed,Object? rejectionReason = freezed,Object? documentMime = freezed,Object? hasDocument = null,Object? documentDeleted = null,}) {
  return _then(AdminStudentDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as String,accountEmail: freezed == accountEmail ? _self.accountEmail : accountEmail // ignore: cast_nullable_to_non_nullable
as String?,fullName: freezed == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String?,universityEmail: freezed == universityEmail ? _self.universityEmail : universityEmail // ignore: cast_nullable_to_non_nullable
as String?,emailVerifiedAt: freezed == emailVerifiedAt ? _self.emailVerifiedAt : emailVerifiedAt // ignore: cast_nullable_to_non_nullable
as String?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as String?,reviewedByEmail: freezed == reviewedByEmail ? _self.reviewedByEmail : reviewedByEmail // ignore: cast_nullable_to_non_nullable
as String?,approvedAt: freezed == approvedAt ? _self.approvedAt : approvedAt // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,documentMime: freezed == documentMime ? _self.documentMime : documentMime // ignore: cast_nullable_to_non_nullable
as String?,hasDocument: null == hasDocument ? _self.hasDocument : hasDocument // ignore: cast_nullable_to_non_nullable
as bool,documentDeleted: null == documentDeleted ? _self.documentDeleted : documentDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminStudentDto].
extension AdminStudentDtoPatterns on AdminStudentDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminStudentDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminStudentDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminStudentDto value)  $default,){
final _that = this;
switch (_that) {
case _AdminStudentDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminStudentDto value)?  $default,){
final _that = this;
switch (_that) {
case _AdminStudentDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String method,  String status,  String submittedAt,  String? accountEmail,  String? fullName,  String? universityEmail,  String? emailVerifiedAt,  String? reviewedAt,  String? reviewedByEmail,  String? approvedAt,  String? expiresAt,  String? rejectionReason,  String? documentMime,  bool hasDocument,  bool documentDeleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminStudentDto() when $default != null:
return $default(_that.id,_that.method,_that.status,_that.submittedAt,_that.accountEmail,_that.fullName,_that.universityEmail,_that.emailVerifiedAt,_that.reviewedAt,_that.reviewedByEmail,_that.approvedAt,_that.expiresAt,_that.rejectionReason,_that.documentMime,_that.hasDocument,_that.documentDeleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String method,  String status,  String submittedAt,  String? accountEmail,  String? fullName,  String? universityEmail,  String? emailVerifiedAt,  String? reviewedAt,  String? reviewedByEmail,  String? approvedAt,  String? expiresAt,  String? rejectionReason,  String? documentMime,  bool hasDocument,  bool documentDeleted)  $default,) {final _that = this;
switch (_that) {
case _AdminStudentDto():
return $default(_that.id,_that.method,_that.status,_that.submittedAt,_that.accountEmail,_that.fullName,_that.universityEmail,_that.emailVerifiedAt,_that.reviewedAt,_that.reviewedByEmail,_that.approvedAt,_that.expiresAt,_that.rejectionReason,_that.documentMime,_that.hasDocument,_that.documentDeleted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String method,  String status,  String submittedAt,  String? accountEmail,  String? fullName,  String? universityEmail,  String? emailVerifiedAt,  String? reviewedAt,  String? reviewedByEmail,  String? approvedAt,  String? expiresAt,  String? rejectionReason,  String? documentMime,  bool hasDocument,  bool documentDeleted)?  $default,) {final _that = this;
switch (_that) {
case _AdminStudentDto() when $default != null:
return $default(_that.id,_that.method,_that.status,_that.submittedAt,_that.accountEmail,_that.fullName,_that.universityEmail,_that.emailVerifiedAt,_that.reviewedAt,_that.reviewedByEmail,_that.approvedAt,_that.expiresAt,_that.rejectionReason,_that.documentMime,_that.hasDocument,_that.documentDeleted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminStudentDto implements AdminStudentDto {
  const _AdminStudentDto({required this.id, required this.method, required this.status, required this.submittedAt, this.accountEmail, this.fullName, this.universityEmail, this.emailVerifiedAt, this.reviewedAt, this.reviewedByEmail, this.approvedAt, this.expiresAt, this.rejectionReason, this.documentMime, this.hasDocument = false, this.documentDeleted = false});
  factory _AdminStudentDto.fromJson(Map<String, dynamic> json) => _$AdminStudentDtoFromJson(json);

@override final  String id;
@override final  String method;
@override final  String status;
@override final  String submittedAt;
@override final  String? accountEmail;
@override final  String? fullName;
@override final  String? universityEmail;
@override final  String? emailVerifiedAt;
@override final  String? reviewedAt;
@override final  String? reviewedByEmail;
@override final  String? approvedAt;
@override final  String? expiresAt;
@override final  String? rejectionReason;
@override final  String? documentMime;
@override@JsonKey() final  bool hasDocument;
@override@JsonKey() final  bool documentDeleted;

/// Create a copy of AdminStudentDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminStudentDtoCopyWith<_AdminStudentDto> get copyWith => __$AdminStudentDtoCopyWithImpl<_AdminStudentDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminStudentDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminStudentDto&&(identical(other.id, id) || other.id == id)&&(identical(other.method, method) || other.method == method)&&(identical(other.status, status) || other.status == status)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.accountEmail, accountEmail) || other.accountEmail == accountEmail)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.universityEmail, universityEmail) || other.universityEmail == universityEmail)&&(identical(other.emailVerifiedAt, emailVerifiedAt) || other.emailVerifiedAt == emailVerifiedAt)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.reviewedByEmail, reviewedByEmail) || other.reviewedByEmail == reviewedByEmail)&&(identical(other.approvedAt, approvedAt) || other.approvedAt == approvedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.documentMime, documentMime) || other.documentMime == documentMime)&&(identical(other.hasDocument, hasDocument) || other.hasDocument == hasDocument)&&(identical(other.documentDeleted, documentDeleted) || other.documentDeleted == documentDeleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,method,status,submittedAt,accountEmail,fullName,universityEmail,emailVerifiedAt,reviewedAt,reviewedByEmail,approvedAt,expiresAt,rejectionReason,documentMime,hasDocument,documentDeleted);
}

@override
String toString() {
    return 'AdminStudentDto(id: $id, method: $method, status: $status, submittedAt: $submittedAt, accountEmail: $accountEmail, fullName: $fullName, universityEmail: $universityEmail, emailVerifiedAt: $emailVerifiedAt, reviewedAt: $reviewedAt, reviewedByEmail: $reviewedByEmail, approvedAt: $approvedAt, expiresAt: $expiresAt, rejectionReason: $rejectionReason, documentMime: $documentMime, hasDocument: $hasDocument, documentDeleted: $documentDeleted)';
}


}

/// @nodoc
abstract mixin class _$AdminStudentDtoCopyWith<$Res> implements $AdminStudentDtoCopyWith<$Res> {
  factory _$AdminStudentDtoCopyWith(_AdminStudentDto value, $Res Function(_AdminStudentDto) _then) = __$AdminStudentDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String method, String status, String submittedAt, String? accountEmail, String? fullName, String? universityEmail, String? emailVerifiedAt, String? reviewedAt, String? reviewedByEmail, String? approvedAt, String? expiresAt, String? rejectionReason, String? documentMime, bool hasDocument, bool documentDeleted
});




}
/// @nodoc
class __$AdminStudentDtoCopyWithImpl<$Res>
    implements _$AdminStudentDtoCopyWith<$Res> {
  __$AdminStudentDtoCopyWithImpl(this._self, this._then);

  final _AdminStudentDto _self;
  final $Res Function(_AdminStudentDto) _then;

/// Create a copy of AdminStudentDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? method = null,Object? status = null,Object? submittedAt = null,Object? accountEmail = freezed,Object? fullName = freezed,Object? universityEmail = freezed,Object? emailVerifiedAt = freezed,Object? reviewedAt = freezed,Object? reviewedByEmail = freezed,Object? approvedAt = freezed,Object? expiresAt = freezed,Object? rejectionReason = freezed,Object? documentMime = freezed,Object? hasDocument = null,Object? documentDeleted = null,}) {
  return _then(_AdminStudentDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as String,accountEmail: freezed == accountEmail ? _self.accountEmail : accountEmail // ignore: cast_nullable_to_non_nullable
as String?,fullName: freezed == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String?,universityEmail: freezed == universityEmail ? _self.universityEmail : universityEmail // ignore: cast_nullable_to_non_nullable
as String?,emailVerifiedAt: freezed == emailVerifiedAt ? _self.emailVerifiedAt : emailVerifiedAt // ignore: cast_nullable_to_non_nullable
as String?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as String?,reviewedByEmail: freezed == reviewedByEmail ? _self.reviewedByEmail : reviewedByEmail // ignore: cast_nullable_to_non_nullable
as String?,approvedAt: freezed == approvedAt ? _self.approvedAt : approvedAt // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,documentMime: freezed == documentMime ? _self.documentMime : documentMime // ignore: cast_nullable_to_non_nullable
as String?,hasDocument: null == hasDocument ? _self.hasDocument : hasDocument // ignore: cast_nullable_to_non_nullable
as bool,documentDeleted: null == documentDeleted ? _self.documentDeleted : documentDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
