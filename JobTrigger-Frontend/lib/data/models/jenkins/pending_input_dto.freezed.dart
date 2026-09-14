// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pending_input_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PendingInputDto {

 String get id; String? get message; String get proceedText; String get abortText; List<ParameterDefinitionDto> get inputs;
/// Create a copy of PendingInputDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingInputDtoCopyWith<PendingInputDto> get copyWith => _$PendingInputDtoCopyWithImpl<PendingInputDto>(this as PendingInputDto, _$identity);

  /// Serializes this PendingInputDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingInputDto&&(identical(other.id, id) || other.id == id)&&(identical(other.message, message) || other.message == message)&&(identical(other.proceedText, proceedText) || other.proceedText == proceedText)&&(identical(other.abortText, abortText) || other.abortText == abortText)&&const DeepCollectionEquality().equals(other.inputs, inputs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,message,proceedText,abortText,const DeepCollectionEquality().hash(inputs));

@override
String toString() {
  return 'PendingInputDto(id: $id, message: $message, proceedText: $proceedText, abortText: $abortText, inputs: $inputs)';
}


}

/// @nodoc
abstract mixin class $PendingInputDtoCopyWith<$Res>  {
  factory $PendingInputDtoCopyWith(PendingInputDto value, $Res Function(PendingInputDto) _then) = _$PendingInputDtoCopyWithImpl;
@useResult
$Res call({
 String id, String? message, String proceedText, String abortText, List<ParameterDefinitionDto> inputs
});




}
/// @nodoc
class _$PendingInputDtoCopyWithImpl<$Res>
    implements $PendingInputDtoCopyWith<$Res> {
  _$PendingInputDtoCopyWithImpl(this._self, this._then);

  final PendingInputDto _self;
  final $Res Function(PendingInputDto) _then;

/// Create a copy of PendingInputDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? message = freezed,Object? proceedText = null,Object? abortText = null,Object? inputs = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,proceedText: null == proceedText ? _self.proceedText : proceedText // ignore: cast_nullable_to_non_nullable
as String,abortText: null == abortText ? _self.abortText : abortText // ignore: cast_nullable_to_non_nullable
as String,inputs: null == inputs ? _self.inputs : inputs // ignore: cast_nullable_to_non_nullable
as List<ParameterDefinitionDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingInputDto].
extension PendingInputDtoPatterns on PendingInputDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingInputDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingInputDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingInputDto value)  $default,){
final _that = this;
switch (_that) {
case _PendingInputDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingInputDto value)?  $default,){
final _that = this;
switch (_that) {
case _PendingInputDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? message,  String proceedText,  String abortText,  List<ParameterDefinitionDto> inputs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingInputDto() when $default != null:
return $default(_that.id,_that.message,_that.proceedText,_that.abortText,_that.inputs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? message,  String proceedText,  String abortText,  List<ParameterDefinitionDto> inputs)  $default,) {final _that = this;
switch (_that) {
case _PendingInputDto():
return $default(_that.id,_that.message,_that.proceedText,_that.abortText,_that.inputs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? message,  String proceedText,  String abortText,  List<ParameterDefinitionDto> inputs)?  $default,) {final _that = this;
switch (_that) {
case _PendingInputDto() when $default != null:
return $default(_that.id,_that.message,_that.proceedText,_that.abortText,_that.inputs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PendingInputDto implements PendingInputDto {
  const _PendingInputDto({required this.id, this.message, this.proceedText = 'Proceed', this.abortText = 'Abort', final  List<ParameterDefinitionDto> inputs = const <ParameterDefinitionDto>[]}): _inputs = inputs;
  factory _PendingInputDto.fromJson(Map<String, dynamic> json) => _$PendingInputDtoFromJson(json);

@override final  String id;
@override final  String? message;
@override@JsonKey() final  String proceedText;
@override@JsonKey() final  String abortText;
 final  List<ParameterDefinitionDto> _inputs;
@override@JsonKey() List<ParameterDefinitionDto> get inputs {
  if (_inputs is EqualUnmodifiableListView) return _inputs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_inputs);
}


/// Create a copy of PendingInputDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingInputDtoCopyWith<_PendingInputDto> get copyWith => __$PendingInputDtoCopyWithImpl<_PendingInputDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PendingInputDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingInputDto&&(identical(other.id, id) || other.id == id)&&(identical(other.message, message) || other.message == message)&&(identical(other.proceedText, proceedText) || other.proceedText == proceedText)&&(identical(other.abortText, abortText) || other.abortText == abortText)&&const DeepCollectionEquality().equals(other._inputs, _inputs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,message,proceedText,abortText,const DeepCollectionEquality().hash(_inputs));

@override
String toString() {
  return 'PendingInputDto(id: $id, message: $message, proceedText: $proceedText, abortText: $abortText, inputs: $inputs)';
}


}

/// @nodoc
abstract mixin class _$PendingInputDtoCopyWith<$Res> implements $PendingInputDtoCopyWith<$Res> {
  factory _$PendingInputDtoCopyWith(_PendingInputDto value, $Res Function(_PendingInputDto) _then) = __$PendingInputDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String? message, String proceedText, String abortText, List<ParameterDefinitionDto> inputs
});




}
/// @nodoc
class __$PendingInputDtoCopyWithImpl<$Res>
    implements _$PendingInputDtoCopyWith<$Res> {
  __$PendingInputDtoCopyWithImpl(this._self, this._then);

  final _PendingInputDto _self;
  final $Res Function(_PendingInputDto) _then;

/// Create a copy of PendingInputDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? message = freezed,Object? proceedText = null,Object? abortText = null,Object? inputs = null,}) {
  return _then(_PendingInputDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,proceedText: null == proceedText ? _self.proceedText : proceedText // ignore: cast_nullable_to_non_nullable
as String,abortText: null == abortText ? _self.abortText : abortText // ignore: cast_nullable_to_non_nullable
as String,inputs: null == inputs ? _self._inputs : inputs // ignore: cast_nullable_to_non_nullable
as List<ParameterDefinitionDto>,
  ));
}


}

// dart format on
