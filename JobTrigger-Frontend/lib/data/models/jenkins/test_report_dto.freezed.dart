// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'test_report_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TestReportDto {

 int get passCount; int get failCount; int get skipCount;// `suites[].cases[]` is polymorphic-in-depth (nested test suites, each
// holding individual cases) -- flatten straight to the
// `ClassName.testName` strings actually rendered, same reasoning as
// `causes`/`changes` on `JenkinsBuildDto`.
@JsonKey(name: 'suites', fromJson: _failingTestsFromJson, includeToJson: false) List<String> get failingTests;
/// Create a copy of TestReportDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TestReportDtoCopyWith<TestReportDto> get copyWith => _$TestReportDtoCopyWithImpl<TestReportDto>(this as TestReportDto, _$identity);

  /// Serializes this TestReportDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TestReportDto&&(identical(other.passCount, passCount) || other.passCount == passCount)&&(identical(other.failCount, failCount) || other.failCount == failCount)&&(identical(other.skipCount, skipCount) || other.skipCount == skipCount)&&const DeepCollectionEquality().equals(other.failingTests, failingTests));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,passCount,failCount,skipCount,const DeepCollectionEquality().hash(failingTests));

@override
String toString() {
  return 'TestReportDto(passCount: $passCount, failCount: $failCount, skipCount: $skipCount, failingTests: $failingTests)';
}


}

/// @nodoc
abstract mixin class $TestReportDtoCopyWith<$Res>  {
  factory $TestReportDtoCopyWith(TestReportDto value, $Res Function(TestReportDto) _then) = _$TestReportDtoCopyWithImpl;
@useResult
$Res call({
 int passCount, int failCount, int skipCount,@JsonKey(name: 'suites', fromJson: _failingTestsFromJson, includeToJson: false) List<String> failingTests
});




}
/// @nodoc
class _$TestReportDtoCopyWithImpl<$Res>
    implements $TestReportDtoCopyWith<$Res> {
  _$TestReportDtoCopyWithImpl(this._self, this._then);

  final TestReportDto _self;
  final $Res Function(TestReportDto) _then;

/// Create a copy of TestReportDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? passCount = null,Object? failCount = null,Object? skipCount = null,Object? failingTests = null,}) {
  return _then(_self.copyWith(
passCount: null == passCount ? _self.passCount : passCount // ignore: cast_nullable_to_non_nullable
as int,failCount: null == failCount ? _self.failCount : failCount // ignore: cast_nullable_to_non_nullable
as int,skipCount: null == skipCount ? _self.skipCount : skipCount // ignore: cast_nullable_to_non_nullable
as int,failingTests: null == failingTests ? _self.failingTests : failingTests // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [TestReportDto].
extension TestReportDtoPatterns on TestReportDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TestReportDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TestReportDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TestReportDto value)  $default,){
final _that = this;
switch (_that) {
case _TestReportDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TestReportDto value)?  $default,){
final _that = this;
switch (_that) {
case _TestReportDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int passCount,  int failCount,  int skipCount, @JsonKey(name: 'suites', fromJson: _failingTestsFromJson, includeToJson: false)  List<String> failingTests)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TestReportDto() when $default != null:
return $default(_that.passCount,_that.failCount,_that.skipCount,_that.failingTests);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int passCount,  int failCount,  int skipCount, @JsonKey(name: 'suites', fromJson: _failingTestsFromJson, includeToJson: false)  List<String> failingTests)  $default,) {final _that = this;
switch (_that) {
case _TestReportDto():
return $default(_that.passCount,_that.failCount,_that.skipCount,_that.failingTests);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int passCount,  int failCount,  int skipCount, @JsonKey(name: 'suites', fromJson: _failingTestsFromJson, includeToJson: false)  List<String> failingTests)?  $default,) {final _that = this;
switch (_that) {
case _TestReportDto() when $default != null:
return $default(_that.passCount,_that.failCount,_that.skipCount,_that.failingTests);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TestReportDto implements TestReportDto {
  const _TestReportDto({this.passCount = 0, this.failCount = 0, this.skipCount = 0, @JsonKey(name: 'suites', fromJson: _failingTestsFromJson, includeToJson: false) final  List<String> failingTests = const <String>[]}): _failingTests = failingTests;
  factory _TestReportDto.fromJson(Map<String, dynamic> json) => _$TestReportDtoFromJson(json);

@override@JsonKey() final  int passCount;
@override@JsonKey() final  int failCount;
@override@JsonKey() final  int skipCount;
// `suites[].cases[]` is polymorphic-in-depth (nested test suites, each
// holding individual cases) -- flatten straight to the
// `ClassName.testName` strings actually rendered, same reasoning as
// `causes`/`changes` on `JenkinsBuildDto`.
 final  List<String> _failingTests;
// `suites[].cases[]` is polymorphic-in-depth (nested test suites, each
// holding individual cases) -- flatten straight to the
// `ClassName.testName` strings actually rendered, same reasoning as
// `causes`/`changes` on `JenkinsBuildDto`.
@override@JsonKey(name: 'suites', fromJson: _failingTestsFromJson, includeToJson: false) List<String> get failingTests {
  if (_failingTests is EqualUnmodifiableListView) return _failingTests;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_failingTests);
}


/// Create a copy of TestReportDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TestReportDtoCopyWith<_TestReportDto> get copyWith => __$TestReportDtoCopyWithImpl<_TestReportDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TestReportDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TestReportDto&&(identical(other.passCount, passCount) || other.passCount == passCount)&&(identical(other.failCount, failCount) || other.failCount == failCount)&&(identical(other.skipCount, skipCount) || other.skipCount == skipCount)&&const DeepCollectionEquality().equals(other._failingTests, _failingTests));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,passCount,failCount,skipCount,const DeepCollectionEquality().hash(_failingTests));

@override
String toString() {
  return 'TestReportDto(passCount: $passCount, failCount: $failCount, skipCount: $skipCount, failingTests: $failingTests)';
}


}

/// @nodoc
abstract mixin class _$TestReportDtoCopyWith<$Res> implements $TestReportDtoCopyWith<$Res> {
  factory _$TestReportDtoCopyWith(_TestReportDto value, $Res Function(_TestReportDto) _then) = __$TestReportDtoCopyWithImpl;
@override @useResult
$Res call({
 int passCount, int failCount, int skipCount,@JsonKey(name: 'suites', fromJson: _failingTestsFromJson, includeToJson: false) List<String> failingTests
});




}
/// @nodoc
class __$TestReportDtoCopyWithImpl<$Res>
    implements _$TestReportDtoCopyWith<$Res> {
  __$TestReportDtoCopyWithImpl(this._self, this._then);

  final _TestReportDto _self;
  final $Res Function(_TestReportDto) _then;

/// Create a copy of TestReportDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? passCount = null,Object? failCount = null,Object? skipCount = null,Object? failingTests = null,}) {
  return _then(_TestReportDto(
passCount: null == passCount ? _self.passCount : passCount // ignore: cast_nullable_to_non_nullable
as int,failCount: null == failCount ? _self.failCount : failCount // ignore: cast_nullable_to_non_nullable
as int,skipCount: null == skipCount ? _self.skipCount : skipCount // ignore: cast_nullable_to_non_nullable
as int,failingTests: null == failingTests ? _self._failingTests : failingTests // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
