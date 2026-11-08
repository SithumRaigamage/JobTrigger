// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'github_job_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GitHubJobDto {

 int get id; String get name; String get status; String? get conclusion; List<GitHubStepDto> get steps;
/// Create a copy of GitHubJobDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitHubJobDtoCopyWith<GitHubJobDto> get copyWith => _$GitHubJobDtoCopyWithImpl<GitHubJobDto>(this as GitHubJobDto, _$identity);

  /// Serializes this GitHubJobDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitHubJobDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.conclusion, conclusion) || other.conclusion == conclusion)&&const DeepCollectionEquality().equals(other.steps, steps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,status,conclusion,const DeepCollectionEquality().hash(steps));

@override
String toString() {
  return 'GitHubJobDto(id: $id, name: $name, status: $status, conclusion: $conclusion, steps: $steps)';
}


}

/// @nodoc
abstract mixin class $GitHubJobDtoCopyWith<$Res>  {
  factory $GitHubJobDtoCopyWith(GitHubJobDto value, $Res Function(GitHubJobDto) _then) = _$GitHubJobDtoCopyWithImpl;
@useResult
$Res call({
 int id, String name, String status, String? conclusion, List<GitHubStepDto> steps
});




}
/// @nodoc
class _$GitHubJobDtoCopyWithImpl<$Res>
    implements $GitHubJobDtoCopyWith<$Res> {
  _$GitHubJobDtoCopyWithImpl(this._self, this._then);

  final GitHubJobDto _self;
  final $Res Function(GitHubJobDto) _then;

/// Create a copy of GitHubJobDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? status = null,Object? conclusion = freezed,Object? steps = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,conclusion: freezed == conclusion ? _self.conclusion : conclusion // ignore: cast_nullable_to_non_nullable
as String?,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<GitHubStepDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [GitHubJobDto].
extension GitHubJobDtoPatterns on GitHubJobDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GitHubJobDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GitHubJobDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GitHubJobDto value)  $default,){
final _that = this;
switch (_that) {
case _GitHubJobDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GitHubJobDto value)?  $default,){
final _that = this;
switch (_that) {
case _GitHubJobDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String status,  String? conclusion,  List<GitHubStepDto> steps)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitHubJobDto() when $default != null:
return $default(_that.id,_that.name,_that.status,_that.conclusion,_that.steps);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String status,  String? conclusion,  List<GitHubStepDto> steps)  $default,) {final _that = this;
switch (_that) {
case _GitHubJobDto():
return $default(_that.id,_that.name,_that.status,_that.conclusion,_that.steps);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String status,  String? conclusion,  List<GitHubStepDto> steps)?  $default,) {final _that = this;
switch (_that) {
case _GitHubJobDto() when $default != null:
return $default(_that.id,_that.name,_that.status,_that.conclusion,_that.steps);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GitHubJobDto implements GitHubJobDto {
  const _GitHubJobDto({required this.id, this.name = '', this.status = '', this.conclusion, final  List<GitHubStepDto> steps = const <GitHubStepDto>[]}): _steps = steps;
  factory _GitHubJobDto.fromJson(Map<String, dynamic> json) => _$GitHubJobDtoFromJson(json);

@override final  int id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String status;
@override final  String? conclusion;
 final  List<GitHubStepDto> _steps;
@override@JsonKey() List<GitHubStepDto> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}


/// Create a copy of GitHubJobDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GitHubJobDtoCopyWith<_GitHubJobDto> get copyWith => __$GitHubJobDtoCopyWithImpl<_GitHubJobDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GitHubJobDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitHubJobDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.conclusion, conclusion) || other.conclusion == conclusion)&&const DeepCollectionEquality().equals(other._steps, _steps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,status,conclusion,const DeepCollectionEquality().hash(_steps));

@override
String toString() {
  return 'GitHubJobDto(id: $id, name: $name, status: $status, conclusion: $conclusion, steps: $steps)';
}


}

/// @nodoc
abstract mixin class _$GitHubJobDtoCopyWith<$Res> implements $GitHubJobDtoCopyWith<$Res> {
  factory _$GitHubJobDtoCopyWith(_GitHubJobDto value, $Res Function(_GitHubJobDto) _then) = __$GitHubJobDtoCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String status, String? conclusion, List<GitHubStepDto> steps
});




}
/// @nodoc
class __$GitHubJobDtoCopyWithImpl<$Res>
    implements _$GitHubJobDtoCopyWith<$Res> {
  __$GitHubJobDtoCopyWithImpl(this._self, this._then);

  final _GitHubJobDto _self;
  final $Res Function(_GitHubJobDto) _then;

/// Create a copy of GitHubJobDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? status = null,Object? conclusion = freezed,Object? steps = null,}) {
  return _then(_GitHubJobDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,conclusion: freezed == conclusion ? _self.conclusion : conclusion // ignore: cast_nullable_to_non_nullable
as String?,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<GitHubStepDto>,
  ));
}


}


/// @nodoc
mixin _$GitHubStepDto {

 int get number; String get name; String get status; String? get conclusion;
/// Create a copy of GitHubStepDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitHubStepDtoCopyWith<GitHubStepDto> get copyWith => _$GitHubStepDtoCopyWithImpl<GitHubStepDto>(this as GitHubStepDto, _$identity);

  /// Serializes this GitHubStepDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitHubStepDto&&(identical(other.number, number) || other.number == number)&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.conclusion, conclusion) || other.conclusion == conclusion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,name,status,conclusion);

@override
String toString() {
  return 'GitHubStepDto(number: $number, name: $name, status: $status, conclusion: $conclusion)';
}


}

/// @nodoc
abstract mixin class $GitHubStepDtoCopyWith<$Res>  {
  factory $GitHubStepDtoCopyWith(GitHubStepDto value, $Res Function(GitHubStepDto) _then) = _$GitHubStepDtoCopyWithImpl;
@useResult
$Res call({
 int number, String name, String status, String? conclusion
});




}
/// @nodoc
class _$GitHubStepDtoCopyWithImpl<$Res>
    implements $GitHubStepDtoCopyWith<$Res> {
  _$GitHubStepDtoCopyWithImpl(this._self, this._then);

  final GitHubStepDto _self;
  final $Res Function(GitHubStepDto) _then;

/// Create a copy of GitHubStepDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? number = null,Object? name = null,Object? status = null,Object? conclusion = freezed,}) {
  return _then(_self.copyWith(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,conclusion: freezed == conclusion ? _self.conclusion : conclusion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GitHubStepDto].
extension GitHubStepDtoPatterns on GitHubStepDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GitHubStepDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GitHubStepDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GitHubStepDto value)  $default,){
final _that = this;
switch (_that) {
case _GitHubStepDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GitHubStepDto value)?  $default,){
final _that = this;
switch (_that) {
case _GitHubStepDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int number,  String name,  String status,  String? conclusion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitHubStepDto() when $default != null:
return $default(_that.number,_that.name,_that.status,_that.conclusion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int number,  String name,  String status,  String? conclusion)  $default,) {final _that = this;
switch (_that) {
case _GitHubStepDto():
return $default(_that.number,_that.name,_that.status,_that.conclusion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int number,  String name,  String status,  String? conclusion)?  $default,) {final _that = this;
switch (_that) {
case _GitHubStepDto() when $default != null:
return $default(_that.number,_that.name,_that.status,_that.conclusion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GitHubStepDto implements GitHubStepDto {
  const _GitHubStepDto({this.number = 0, this.name = '', this.status = '', this.conclusion});
  factory _GitHubStepDto.fromJson(Map<String, dynamic> json) => _$GitHubStepDtoFromJson(json);

@override@JsonKey() final  int number;
@override@JsonKey() final  String name;
@override@JsonKey() final  String status;
@override final  String? conclusion;

/// Create a copy of GitHubStepDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GitHubStepDtoCopyWith<_GitHubStepDto> get copyWith => __$GitHubStepDtoCopyWithImpl<_GitHubStepDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GitHubStepDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitHubStepDto&&(identical(other.number, number) || other.number == number)&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.conclusion, conclusion) || other.conclusion == conclusion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,name,status,conclusion);

@override
String toString() {
  return 'GitHubStepDto(number: $number, name: $name, status: $status, conclusion: $conclusion)';
}


}

/// @nodoc
abstract mixin class _$GitHubStepDtoCopyWith<$Res> implements $GitHubStepDtoCopyWith<$Res> {
  factory _$GitHubStepDtoCopyWith(_GitHubStepDto value, $Res Function(_GitHubStepDto) _then) = __$GitHubStepDtoCopyWithImpl;
@override @useResult
$Res call({
 int number, String name, String status, String? conclusion
});




}
/// @nodoc
class __$GitHubStepDtoCopyWithImpl<$Res>
    implements _$GitHubStepDtoCopyWith<$Res> {
  __$GitHubStepDtoCopyWithImpl(this._self, this._then);

  final _GitHubStepDto _self;
  final $Res Function(_GitHubStepDto) _then;

/// Create a copy of GitHubStepDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? number = null,Object? name = null,Object? status = null,Object? conclusion = freezed,}) {
  return _then(_GitHubStepDto(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,conclusion: freezed == conclusion ? _self.conclusion : conclusion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
