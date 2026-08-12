// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'parameter_definition_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ParameterDefinitionDto {

 String get name; String get type;// StringParameterDefinition | ChoiceParameterDefinition | BooleanParameterDefinition
 String? get description; List<String>? get choices;@JsonKey(name: 'defaultParameterValue', fromJson: _defaultValueFromJson) dynamic get defaultValue;
/// Create a copy of ParameterDefinitionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParameterDefinitionDtoCopyWith<ParameterDefinitionDto> get copyWith => _$ParameterDefinitionDtoCopyWithImpl<ParameterDefinitionDto>(this as ParameterDefinitionDto, _$identity);

  /// Serializes this ParameterDefinitionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParameterDefinitionDto&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.choices, choices)&&const DeepCollectionEquality().equals(other.defaultValue, defaultValue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,type,description,const DeepCollectionEquality().hash(choices),const DeepCollectionEquality().hash(defaultValue));

@override
String toString() {
  return 'ParameterDefinitionDto(name: $name, type: $type, description: $description, choices: $choices, defaultValue: $defaultValue)';
}


}

/// @nodoc
abstract mixin class $ParameterDefinitionDtoCopyWith<$Res>  {
  factory $ParameterDefinitionDtoCopyWith(ParameterDefinitionDto value, $Res Function(ParameterDefinitionDto) _then) = _$ParameterDefinitionDtoCopyWithImpl;
@useResult
$Res call({
 String name, String type, String? description, List<String>? choices,@JsonKey(name: 'defaultParameterValue', fromJson: _defaultValueFromJson) dynamic defaultValue
});




}
/// @nodoc
class _$ParameterDefinitionDtoCopyWithImpl<$Res>
    implements $ParameterDefinitionDtoCopyWith<$Res> {
  _$ParameterDefinitionDtoCopyWithImpl(this._self, this._then);

  final ParameterDefinitionDto _self;
  final $Res Function(ParameterDefinitionDto) _then;

/// Create a copy of ParameterDefinitionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? type = null,Object? description = freezed,Object? choices = freezed,Object? defaultValue = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,choices: freezed == choices ? _self.choices : choices // ignore: cast_nullable_to_non_nullable
as List<String>?,defaultValue: freezed == defaultValue ? _self.defaultValue : defaultValue // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}

}


/// Adds pattern-matching-related methods to [ParameterDefinitionDto].
extension ParameterDefinitionDtoPatterns on ParameterDefinitionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParameterDefinitionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParameterDefinitionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParameterDefinitionDto value)  $default,){
final _that = this;
switch (_that) {
case _ParameterDefinitionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParameterDefinitionDto value)?  $default,){
final _that = this;
switch (_that) {
case _ParameterDefinitionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String type,  String? description,  List<String>? choices, @JsonKey(name: 'defaultParameterValue', fromJson: _defaultValueFromJson)  dynamic defaultValue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParameterDefinitionDto() when $default != null:
return $default(_that.name,_that.type,_that.description,_that.choices,_that.defaultValue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String type,  String? description,  List<String>? choices, @JsonKey(name: 'defaultParameterValue', fromJson: _defaultValueFromJson)  dynamic defaultValue)  $default,) {final _that = this;
switch (_that) {
case _ParameterDefinitionDto():
return $default(_that.name,_that.type,_that.description,_that.choices,_that.defaultValue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String type,  String? description,  List<String>? choices, @JsonKey(name: 'defaultParameterValue', fromJson: _defaultValueFromJson)  dynamic defaultValue)?  $default,) {final _that = this;
switch (_that) {
case _ParameterDefinitionDto() when $default != null:
return $default(_that.name,_that.type,_that.description,_that.choices,_that.defaultValue);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ParameterDefinitionDto implements ParameterDefinitionDto {
  const _ParameterDefinitionDto({required this.name, required this.type, this.description, final  List<String>? choices, @JsonKey(name: 'defaultParameterValue', fromJson: _defaultValueFromJson) this.defaultValue}): _choices = choices;
  factory _ParameterDefinitionDto.fromJson(Map<String, dynamic> json) => _$ParameterDefinitionDtoFromJson(json);

@override final  String name;
@override final  String type;
// StringParameterDefinition | ChoiceParameterDefinition | BooleanParameterDefinition
@override final  String? description;
 final  List<String>? _choices;
@override List<String>? get choices {
  final value = _choices;
  if (value == null) return null;
  if (_choices is EqualUnmodifiableListView) return _choices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'defaultParameterValue', fromJson: _defaultValueFromJson) final  dynamic defaultValue;

/// Create a copy of ParameterDefinitionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParameterDefinitionDtoCopyWith<_ParameterDefinitionDto> get copyWith => __$ParameterDefinitionDtoCopyWithImpl<_ParameterDefinitionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParameterDefinitionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParameterDefinitionDto&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._choices, _choices)&&const DeepCollectionEquality().equals(other.defaultValue, defaultValue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,type,description,const DeepCollectionEquality().hash(_choices),const DeepCollectionEquality().hash(defaultValue));

@override
String toString() {
  return 'ParameterDefinitionDto(name: $name, type: $type, description: $description, choices: $choices, defaultValue: $defaultValue)';
}


}

/// @nodoc
abstract mixin class _$ParameterDefinitionDtoCopyWith<$Res> implements $ParameterDefinitionDtoCopyWith<$Res> {
  factory _$ParameterDefinitionDtoCopyWith(_ParameterDefinitionDto value, $Res Function(_ParameterDefinitionDto) _then) = __$ParameterDefinitionDtoCopyWithImpl;
@override @useResult
$Res call({
 String name, String type, String? description, List<String>? choices,@JsonKey(name: 'defaultParameterValue', fromJson: _defaultValueFromJson) dynamic defaultValue
});




}
/// @nodoc
class __$ParameterDefinitionDtoCopyWithImpl<$Res>
    implements _$ParameterDefinitionDtoCopyWith<$Res> {
  __$ParameterDefinitionDtoCopyWithImpl(this._self, this._then);

  final _ParameterDefinitionDto _self;
  final $Res Function(_ParameterDefinitionDto) _then;

/// Create a copy of ParameterDefinitionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? type = null,Object? description = freezed,Object? choices = freezed,Object? defaultValue = freezed,}) {
  return _then(_ParameterDefinitionDto(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,choices: freezed == choices ? _self._choices : choices // ignore: cast_nullable_to_non_nullable
as List<String>?,defaultValue: freezed == defaultValue ? _self.defaultValue : defaultValue // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}


}

// dart format on
