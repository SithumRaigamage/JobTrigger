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

 String get id; String? get message; String get proceedText; String get abortText; List<PendingInputParameterDto> get inputs;
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
 String id, String? message, String proceedText, String abortText, List<PendingInputParameterDto> inputs
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
as List<PendingInputParameterDto>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? message,  String proceedText,  String abortText,  List<PendingInputParameterDto> inputs)?  $default,{required TResult orElse(),}) {final _that = this;
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? message,  String proceedText,  String abortText,  List<PendingInputParameterDto> inputs)  $default,) {final _that = this;
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? message,  String proceedText,  String abortText,  List<PendingInputParameterDto> inputs)?  $default,) {final _that = this;
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
  const _PendingInputDto({required this.id, this.message, this.proceedText = 'Proceed', this.abortText = 'Abort', final  List<PendingInputParameterDto> inputs = const <PendingInputParameterDto>[]}): _inputs = inputs;
  factory _PendingInputDto.fromJson(Map<String, dynamic> json) => _$PendingInputDtoFromJson(json);

@override final  String id;
@override final  String? message;
@override@JsonKey() final  String proceedText;
@override@JsonKey() final  String abortText;
 final  List<PendingInputParameterDto> _inputs;
@override@JsonKey() List<PendingInputParameterDto> get inputs {
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
 String id, String? message, String proceedText, String abortText, List<PendingInputParameterDto> inputs
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
as List<PendingInputParameterDto>,
  ));
}


}


/// @nodoc
mixin _$PendingInputParameterDto {

 String get name; String get type; String? get description; PendingInputParameterDefinitionDto? get definition;
/// Create a copy of PendingInputParameterDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingInputParameterDtoCopyWith<PendingInputParameterDto> get copyWith => _$PendingInputParameterDtoCopyWithImpl<PendingInputParameterDto>(this as PendingInputParameterDto, _$identity);

  /// Serializes this PendingInputParameterDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingInputParameterDto&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.definition, definition) || other.definition == definition));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,type,description,definition);

@override
String toString() {
  return 'PendingInputParameterDto(name: $name, type: $type, description: $description, definition: $definition)';
}


}

/// @nodoc
abstract mixin class $PendingInputParameterDtoCopyWith<$Res>  {
  factory $PendingInputParameterDtoCopyWith(PendingInputParameterDto value, $Res Function(PendingInputParameterDto) _then) = _$PendingInputParameterDtoCopyWithImpl;
@useResult
$Res call({
 String name, String type, String? description, PendingInputParameterDefinitionDto? definition
});


$PendingInputParameterDefinitionDtoCopyWith<$Res>? get definition;

}
/// @nodoc
class _$PendingInputParameterDtoCopyWithImpl<$Res>
    implements $PendingInputParameterDtoCopyWith<$Res> {
  _$PendingInputParameterDtoCopyWithImpl(this._self, this._then);

  final PendingInputParameterDto _self;
  final $Res Function(PendingInputParameterDto) _then;

/// Create a copy of PendingInputParameterDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? type = null,Object? description = freezed,Object? definition = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,definition: freezed == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as PendingInputParameterDefinitionDto?,
  ));
}
/// Create a copy of PendingInputParameterDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PendingInputParameterDefinitionDtoCopyWith<$Res>? get definition {
    if (_self.definition == null) {
    return null;
  }

  return $PendingInputParameterDefinitionDtoCopyWith<$Res>(_self.definition!, (value) {
    return _then(_self.copyWith(definition: value));
  });
}
}


/// Adds pattern-matching-related methods to [PendingInputParameterDto].
extension PendingInputParameterDtoPatterns on PendingInputParameterDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingInputParameterDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingInputParameterDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingInputParameterDto value)  $default,){
final _that = this;
switch (_that) {
case _PendingInputParameterDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingInputParameterDto value)?  $default,){
final _that = this;
switch (_that) {
case _PendingInputParameterDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String type,  String? description,  PendingInputParameterDefinitionDto? definition)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingInputParameterDto() when $default != null:
return $default(_that.name,_that.type,_that.description,_that.definition);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String type,  String? description,  PendingInputParameterDefinitionDto? definition)  $default,) {final _that = this;
switch (_that) {
case _PendingInputParameterDto():
return $default(_that.name,_that.type,_that.description,_that.definition);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String type,  String? description,  PendingInputParameterDefinitionDto? definition)?  $default,) {final _that = this;
switch (_that) {
case _PendingInputParameterDto() when $default != null:
return $default(_that.name,_that.type,_that.description,_that.definition);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PendingInputParameterDto implements PendingInputParameterDto {
  const _PendingInputParameterDto({required this.name, required this.type, this.description, this.definition});
  factory _PendingInputParameterDto.fromJson(Map<String, dynamic> json) => _$PendingInputParameterDtoFromJson(json);

@override final  String name;
@override final  String type;
@override final  String? description;
@override final  PendingInputParameterDefinitionDto? definition;

/// Create a copy of PendingInputParameterDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingInputParameterDtoCopyWith<_PendingInputParameterDto> get copyWith => __$PendingInputParameterDtoCopyWithImpl<_PendingInputParameterDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PendingInputParameterDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingInputParameterDto&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.definition, definition) || other.definition == definition));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,type,description,definition);

@override
String toString() {
  return 'PendingInputParameterDto(name: $name, type: $type, description: $description, definition: $definition)';
}


}

/// @nodoc
abstract mixin class _$PendingInputParameterDtoCopyWith<$Res> implements $PendingInputParameterDtoCopyWith<$Res> {
  factory _$PendingInputParameterDtoCopyWith(_PendingInputParameterDto value, $Res Function(_PendingInputParameterDto) _then) = __$PendingInputParameterDtoCopyWithImpl;
@override @useResult
$Res call({
 String name, String type, String? description, PendingInputParameterDefinitionDto? definition
});


@override $PendingInputParameterDefinitionDtoCopyWith<$Res>? get definition;

}
/// @nodoc
class __$PendingInputParameterDtoCopyWithImpl<$Res>
    implements _$PendingInputParameterDtoCopyWith<$Res> {
  __$PendingInputParameterDtoCopyWithImpl(this._self, this._then);

  final _PendingInputParameterDto _self;
  final $Res Function(_PendingInputParameterDto) _then;

/// Create a copy of PendingInputParameterDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? type = null,Object? description = freezed,Object? definition = freezed,}) {
  return _then(_PendingInputParameterDto(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,definition: freezed == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as PendingInputParameterDefinitionDto?,
  ));
}

/// Create a copy of PendingInputParameterDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PendingInputParameterDefinitionDtoCopyWith<$Res>? get definition {
    if (_self.definition == null) {
    return null;
  }

  return $PendingInputParameterDefinitionDtoCopyWith<$Res>(_self.definition!, (value) {
    return _then(_self.copyWith(definition: value));
  });
}
}


/// @nodoc
mixin _$PendingInputParameterDefinitionDto {

// Polymorphic (string/bool/number) by parameter type, like
// `ParameterDefinitionDto.defaultValue`.
 dynamic get defaultVal; List<String>? get choices;
/// Create a copy of PendingInputParameterDefinitionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingInputParameterDefinitionDtoCopyWith<PendingInputParameterDefinitionDto> get copyWith => _$PendingInputParameterDefinitionDtoCopyWithImpl<PendingInputParameterDefinitionDto>(this as PendingInputParameterDefinitionDto, _$identity);

  /// Serializes this PendingInputParameterDefinitionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingInputParameterDefinitionDto&&const DeepCollectionEquality().equals(other.defaultVal, defaultVal)&&const DeepCollectionEquality().equals(other.choices, choices));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(defaultVal),const DeepCollectionEquality().hash(choices));

@override
String toString() {
  return 'PendingInputParameterDefinitionDto(defaultVal: $defaultVal, choices: $choices)';
}


}

/// @nodoc
abstract mixin class $PendingInputParameterDefinitionDtoCopyWith<$Res>  {
  factory $PendingInputParameterDefinitionDtoCopyWith(PendingInputParameterDefinitionDto value, $Res Function(PendingInputParameterDefinitionDto) _then) = _$PendingInputParameterDefinitionDtoCopyWithImpl;
@useResult
$Res call({
 dynamic defaultVal, List<String>? choices
});




}
/// @nodoc
class _$PendingInputParameterDefinitionDtoCopyWithImpl<$Res>
    implements $PendingInputParameterDefinitionDtoCopyWith<$Res> {
  _$PendingInputParameterDefinitionDtoCopyWithImpl(this._self, this._then);

  final PendingInputParameterDefinitionDto _self;
  final $Res Function(PendingInputParameterDefinitionDto) _then;

/// Create a copy of PendingInputParameterDefinitionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? defaultVal = freezed,Object? choices = freezed,}) {
  return _then(_self.copyWith(
defaultVal: freezed == defaultVal ? _self.defaultVal : defaultVal // ignore: cast_nullable_to_non_nullable
as dynamic,choices: freezed == choices ? _self.choices : choices // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingInputParameterDefinitionDto].
extension PendingInputParameterDefinitionDtoPatterns on PendingInputParameterDefinitionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingInputParameterDefinitionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingInputParameterDefinitionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingInputParameterDefinitionDto value)  $default,){
final _that = this;
switch (_that) {
case _PendingInputParameterDefinitionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingInputParameterDefinitionDto value)?  $default,){
final _that = this;
switch (_that) {
case _PendingInputParameterDefinitionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( dynamic defaultVal,  List<String>? choices)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingInputParameterDefinitionDto() when $default != null:
return $default(_that.defaultVal,_that.choices);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( dynamic defaultVal,  List<String>? choices)  $default,) {final _that = this;
switch (_that) {
case _PendingInputParameterDefinitionDto():
return $default(_that.defaultVal,_that.choices);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( dynamic defaultVal,  List<String>? choices)?  $default,) {final _that = this;
switch (_that) {
case _PendingInputParameterDefinitionDto() when $default != null:
return $default(_that.defaultVal,_that.choices);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PendingInputParameterDefinitionDto implements PendingInputParameterDefinitionDto {
  const _PendingInputParameterDefinitionDto({this.defaultVal, final  List<String>? choices}): _choices = choices;
  factory _PendingInputParameterDefinitionDto.fromJson(Map<String, dynamic> json) => _$PendingInputParameterDefinitionDtoFromJson(json);

// Polymorphic (string/bool/number) by parameter type, like
// `ParameterDefinitionDto.defaultValue`.
@override final  dynamic defaultVal;
 final  List<String>? _choices;
@override List<String>? get choices {
  final value = _choices;
  if (value == null) return null;
  if (_choices is EqualUnmodifiableListView) return _choices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of PendingInputParameterDefinitionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingInputParameterDefinitionDtoCopyWith<_PendingInputParameterDefinitionDto> get copyWith => __$PendingInputParameterDefinitionDtoCopyWithImpl<_PendingInputParameterDefinitionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PendingInputParameterDefinitionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingInputParameterDefinitionDto&&const DeepCollectionEquality().equals(other.defaultVal, defaultVal)&&const DeepCollectionEquality().equals(other._choices, _choices));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(defaultVal),const DeepCollectionEquality().hash(_choices));

@override
String toString() {
  return 'PendingInputParameterDefinitionDto(defaultVal: $defaultVal, choices: $choices)';
}


}

/// @nodoc
abstract mixin class _$PendingInputParameterDefinitionDtoCopyWith<$Res> implements $PendingInputParameterDefinitionDtoCopyWith<$Res> {
  factory _$PendingInputParameterDefinitionDtoCopyWith(_PendingInputParameterDefinitionDto value, $Res Function(_PendingInputParameterDefinitionDto) _then) = __$PendingInputParameterDefinitionDtoCopyWithImpl;
@override @useResult
$Res call({
 dynamic defaultVal, List<String>? choices
});




}
/// @nodoc
class __$PendingInputParameterDefinitionDtoCopyWithImpl<$Res>
    implements _$PendingInputParameterDefinitionDtoCopyWith<$Res> {
  __$PendingInputParameterDefinitionDtoCopyWithImpl(this._self, this._then);

  final _PendingInputParameterDefinitionDto _self;
  final $Res Function(_PendingInputParameterDefinitionDto) _then;

/// Create a copy of PendingInputParameterDefinitionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? defaultVal = freezed,Object? choices = freezed,}) {
  return _then(_PendingInputParameterDefinitionDto(
defaultVal: freezed == defaultVal ? _self.defaultVal : defaultVal // ignore: cast_nullable_to_non_nullable
as dynamic,choices: freezed == choices ? _self._choices : choices // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

// dart format on
