// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'queue_item_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QueueItemDto {

 String? get why; bool get cancelled; QueueExecutableDto? get executable;
/// Create a copy of QueueItemDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueueItemDtoCopyWith<QueueItemDto> get copyWith => _$QueueItemDtoCopyWithImpl<QueueItemDto>(this as QueueItemDto, _$identity);

  /// Serializes this QueueItemDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueueItemDto&&(identical(other.why, why) || other.why == why)&&(identical(other.cancelled, cancelled) || other.cancelled == cancelled)&&(identical(other.executable, executable) || other.executable == executable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,why,cancelled,executable);

@override
String toString() {
  return 'QueueItemDto(why: $why, cancelled: $cancelled, executable: $executable)';
}


}

/// @nodoc
abstract mixin class $QueueItemDtoCopyWith<$Res>  {
  factory $QueueItemDtoCopyWith(QueueItemDto value, $Res Function(QueueItemDto) _then) = _$QueueItemDtoCopyWithImpl;
@useResult
$Res call({
 String? why, bool cancelled, QueueExecutableDto? executable
});


$QueueExecutableDtoCopyWith<$Res>? get executable;

}
/// @nodoc
class _$QueueItemDtoCopyWithImpl<$Res>
    implements $QueueItemDtoCopyWith<$Res> {
  _$QueueItemDtoCopyWithImpl(this._self, this._then);

  final QueueItemDto _self;
  final $Res Function(QueueItemDto) _then;

/// Create a copy of QueueItemDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? why = freezed,Object? cancelled = null,Object? executable = freezed,}) {
  return _then(_self.copyWith(
why: freezed == why ? _self.why : why // ignore: cast_nullable_to_non_nullable
as String?,cancelled: null == cancelled ? _self.cancelled : cancelled // ignore: cast_nullable_to_non_nullable
as bool,executable: freezed == executable ? _self.executable : executable // ignore: cast_nullable_to_non_nullable
as QueueExecutableDto?,
  ));
}
/// Create a copy of QueueItemDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QueueExecutableDtoCopyWith<$Res>? get executable {
    if (_self.executable == null) {
    return null;
  }

  return $QueueExecutableDtoCopyWith<$Res>(_self.executable!, (value) {
    return _then(_self.copyWith(executable: value));
  });
}
}


/// Adds pattern-matching-related methods to [QueueItemDto].
extension QueueItemDtoPatterns on QueueItemDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QueueItemDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QueueItemDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QueueItemDto value)  $default,){
final _that = this;
switch (_that) {
case _QueueItemDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QueueItemDto value)?  $default,){
final _that = this;
switch (_that) {
case _QueueItemDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? why,  bool cancelled,  QueueExecutableDto? executable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QueueItemDto() when $default != null:
return $default(_that.why,_that.cancelled,_that.executable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? why,  bool cancelled,  QueueExecutableDto? executable)  $default,) {final _that = this;
switch (_that) {
case _QueueItemDto():
return $default(_that.why,_that.cancelled,_that.executable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? why,  bool cancelled,  QueueExecutableDto? executable)?  $default,) {final _that = this;
switch (_that) {
case _QueueItemDto() when $default != null:
return $default(_that.why,_that.cancelled,_that.executable);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QueueItemDto implements QueueItemDto {
  const _QueueItemDto({this.why, this.cancelled = false, this.executable});
  factory _QueueItemDto.fromJson(Map<String, dynamic> json) => _$QueueItemDtoFromJson(json);

@override final  String? why;
@override@JsonKey() final  bool cancelled;
@override final  QueueExecutableDto? executable;

/// Create a copy of QueueItemDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QueueItemDtoCopyWith<_QueueItemDto> get copyWith => __$QueueItemDtoCopyWithImpl<_QueueItemDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QueueItemDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QueueItemDto&&(identical(other.why, why) || other.why == why)&&(identical(other.cancelled, cancelled) || other.cancelled == cancelled)&&(identical(other.executable, executable) || other.executable == executable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,why,cancelled,executable);

@override
String toString() {
  return 'QueueItemDto(why: $why, cancelled: $cancelled, executable: $executable)';
}


}

/// @nodoc
abstract mixin class _$QueueItemDtoCopyWith<$Res> implements $QueueItemDtoCopyWith<$Res> {
  factory _$QueueItemDtoCopyWith(_QueueItemDto value, $Res Function(_QueueItemDto) _then) = __$QueueItemDtoCopyWithImpl;
@override @useResult
$Res call({
 String? why, bool cancelled, QueueExecutableDto? executable
});


@override $QueueExecutableDtoCopyWith<$Res>? get executable;

}
/// @nodoc
class __$QueueItemDtoCopyWithImpl<$Res>
    implements _$QueueItemDtoCopyWith<$Res> {
  __$QueueItemDtoCopyWithImpl(this._self, this._then);

  final _QueueItemDto _self;
  final $Res Function(_QueueItemDto) _then;

/// Create a copy of QueueItemDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? why = freezed,Object? cancelled = null,Object? executable = freezed,}) {
  return _then(_QueueItemDto(
why: freezed == why ? _self.why : why // ignore: cast_nullable_to_non_nullable
as String?,cancelled: null == cancelled ? _self.cancelled : cancelled // ignore: cast_nullable_to_non_nullable
as bool,executable: freezed == executable ? _self.executable : executable // ignore: cast_nullable_to_non_nullable
as QueueExecutableDto?,
  ));
}

/// Create a copy of QueueItemDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QueueExecutableDtoCopyWith<$Res>? get executable {
    if (_self.executable == null) {
    return null;
  }

  return $QueueExecutableDtoCopyWith<$Res>(_self.executable!, (value) {
    return _then(_self.copyWith(executable: value));
  });
}
}


/// @nodoc
mixin _$QueueExecutableDto {

 int get number; String get url;
/// Create a copy of QueueExecutableDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueueExecutableDtoCopyWith<QueueExecutableDto> get copyWith => _$QueueExecutableDtoCopyWithImpl<QueueExecutableDto>(this as QueueExecutableDto, _$identity);

  /// Serializes this QueueExecutableDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueueExecutableDto&&(identical(other.number, number) || other.number == number)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,url);

@override
String toString() {
  return 'QueueExecutableDto(number: $number, url: $url)';
}


}

/// @nodoc
abstract mixin class $QueueExecutableDtoCopyWith<$Res>  {
  factory $QueueExecutableDtoCopyWith(QueueExecutableDto value, $Res Function(QueueExecutableDto) _then) = _$QueueExecutableDtoCopyWithImpl;
@useResult
$Res call({
 int number, String url
});




}
/// @nodoc
class _$QueueExecutableDtoCopyWithImpl<$Res>
    implements $QueueExecutableDtoCopyWith<$Res> {
  _$QueueExecutableDtoCopyWithImpl(this._self, this._then);

  final QueueExecutableDto _self;
  final $Res Function(QueueExecutableDto) _then;

/// Create a copy of QueueExecutableDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? number = null,Object? url = null,}) {
  return _then(_self.copyWith(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [QueueExecutableDto].
extension QueueExecutableDtoPatterns on QueueExecutableDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QueueExecutableDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QueueExecutableDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QueueExecutableDto value)  $default,){
final _that = this;
switch (_that) {
case _QueueExecutableDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QueueExecutableDto value)?  $default,){
final _that = this;
switch (_that) {
case _QueueExecutableDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int number,  String url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QueueExecutableDto() when $default != null:
return $default(_that.number,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int number,  String url)  $default,) {final _that = this;
switch (_that) {
case _QueueExecutableDto():
return $default(_that.number,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int number,  String url)?  $default,) {final _that = this;
switch (_that) {
case _QueueExecutableDto() when $default != null:
return $default(_that.number,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QueueExecutableDto implements QueueExecutableDto {
  const _QueueExecutableDto({required this.number, required this.url});
  factory _QueueExecutableDto.fromJson(Map<String, dynamic> json) => _$QueueExecutableDtoFromJson(json);

@override final  int number;
@override final  String url;

/// Create a copy of QueueExecutableDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QueueExecutableDtoCopyWith<_QueueExecutableDto> get copyWith => __$QueueExecutableDtoCopyWithImpl<_QueueExecutableDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QueueExecutableDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QueueExecutableDto&&(identical(other.number, number) || other.number == number)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,url);

@override
String toString() {
  return 'QueueExecutableDto(number: $number, url: $url)';
}


}

/// @nodoc
abstract mixin class _$QueueExecutableDtoCopyWith<$Res> implements $QueueExecutableDtoCopyWith<$Res> {
  factory _$QueueExecutableDtoCopyWith(_QueueExecutableDto value, $Res Function(_QueueExecutableDto) _then) = __$QueueExecutableDtoCopyWithImpl;
@override @useResult
$Res call({
 int number, String url
});




}
/// @nodoc
class __$QueueExecutableDtoCopyWithImpl<$Res>
    implements _$QueueExecutableDtoCopyWith<$Res> {
  __$QueueExecutableDtoCopyWithImpl(this._self, this._then);

  final _QueueExecutableDto _self;
  final $Res Function(_QueueExecutableDto) _then;

/// Create a copy of QueueExecutableDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? number = null,Object? url = null,}) {
  return _then(_QueueExecutableDto(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
