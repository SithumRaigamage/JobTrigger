// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'support_ticket_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SupportTicketDto {

 String get id; String get category; String get subject; String get message; String get status; String? get createdAt;
/// Create a copy of SupportTicketDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportTicketDtoCopyWith<SupportTicketDto> get copyWith => _$SupportTicketDtoCopyWithImpl<SupportTicketDto>(this as SupportTicketDto, _$identity);

  /// Serializes this SupportTicketDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SupportTicketDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportTicketDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.subject, _this.subject) || other.subject == _this.subject)&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SupportTicketDto;
  return Object.hash(runtimeType,_this.id,_this.category,_this.subject,_this.message,_this.status,_this.createdAt);
}

@override
String toString() {
  final _this = this as SupportTicketDto;
  return 'SupportTicketDto(id: ${_this.id}, category: ${_this.category}, subject: ${_this.subject}, message: ${_this.message}, status: ${_this.status}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $SupportTicketDtoCopyWith<$Res>  {
  factory $SupportTicketDtoCopyWith(SupportTicketDto value, $Res Function(SupportTicketDto) _then) = _$SupportTicketDtoCopyWithImpl;
@useResult
$Res call({
 String id, String category, String subject, String message, String status, String? createdAt
});




}
/// @nodoc
class _$SupportTicketDtoCopyWithImpl<$Res>
    implements $SupportTicketDtoCopyWith<$Res> {
  _$SupportTicketDtoCopyWithImpl(this._self, this._then);

  final SupportTicketDto _self;
  final $Res Function(SupportTicketDto) _then;

/// Create a copy of SupportTicketDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? category = null,Object? subject = null,Object? message = null,Object? status = null,Object? createdAt = freezed,}) {
  return _then(SupportTicketDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SupportTicketDto].
extension SupportTicketDtoPatterns on SupportTicketDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportTicketDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportTicketDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportTicketDto value)  $default,){
final _that = this;
switch (_that) {
case _SupportTicketDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportTicketDto value)?  $default,){
final _that = this;
switch (_that) {
case _SupportTicketDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String category,  String subject,  String message,  String status,  String? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportTicketDto() when $default != null:
return $default(_that.id,_that.category,_that.subject,_that.message,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String category,  String subject,  String message,  String status,  String? createdAt)  $default,) {final _that = this;
switch (_that) {
case _SupportTicketDto():
return $default(_that.id,_that.category,_that.subject,_that.message,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String category,  String subject,  String message,  String status,  String? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _SupportTicketDto() when $default != null:
return $default(_that.id,_that.category,_that.subject,_that.message,_that.status,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupportTicketDto implements SupportTicketDto {
  const _SupportTicketDto({required this.id, required this.category, required this.subject, this.message = '', this.status = 'open', this.createdAt});
  factory _SupportTicketDto.fromJson(Map<String, dynamic> json) => _$SupportTicketDtoFromJson(json);

@override final  String id;
@override final  String category;
@override final  String subject;
@override@JsonKey() final  String message;
@override@JsonKey() final  String status;
@override final  String? createdAt;

/// Create a copy of SupportTicketDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportTicketDtoCopyWith<_SupportTicketDto> get copyWith => __$SupportTicketDtoCopyWithImpl<_SupportTicketDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportTicketDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportTicketDto&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.message, message) || other.message == message)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,category,subject,message,status,createdAt);
}

@override
String toString() {
    return 'SupportTicketDto(id: $id, category: $category, subject: $subject, message: $message, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SupportTicketDtoCopyWith<$Res> implements $SupportTicketDtoCopyWith<$Res> {
  factory _$SupportTicketDtoCopyWith(_SupportTicketDto value, $Res Function(_SupportTicketDto) _then) = __$SupportTicketDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String category, String subject, String message, String status, String? createdAt
});




}
/// @nodoc
class __$SupportTicketDtoCopyWithImpl<$Res>
    implements _$SupportTicketDtoCopyWith<$Res> {
  __$SupportTicketDtoCopyWithImpl(this._self, this._then);

  final _SupportTicketDto _self;
  final $Res Function(_SupportTicketDto) _then;

/// Create a copy of SupportTicketDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? category = null,Object? subject = null,Object? message = null,Object? status = null,Object? createdAt = freezed,}) {
  return _then(_SupportTicketDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
