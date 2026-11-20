// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SubscriptionDto {

 String get plan; bool get billingEnabled; String get status; PlanLimitsDto get limits; PlanFeaturesDto get features; String? get source; String? get productId; String? get periodEnd; bool get willRenew; bool get manageOnWeb; String? get primaryCredentialId; TeamMembershipDto? get team;
/// Create a copy of SubscriptionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionDtoCopyWith<SubscriptionDto> get copyWith => _$SubscriptionDtoCopyWithImpl<SubscriptionDto>(this as SubscriptionDto, _$identity);

  /// Serializes this SubscriptionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SubscriptionDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubscriptionDto&&(identical(other.plan, _this.plan) || other.plan == _this.plan)&&(identical(other.billingEnabled, _this.billingEnabled) || other.billingEnabled == _this.billingEnabled)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.limits, _this.limits) || other.limits == _this.limits)&&(identical(other.features, _this.features) || other.features == _this.features)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.productId, _this.productId) || other.productId == _this.productId)&&(identical(other.periodEnd, _this.periodEnd) || other.periodEnd == _this.periodEnd)&&(identical(other.willRenew, _this.willRenew) || other.willRenew == _this.willRenew)&&(identical(other.manageOnWeb, _this.manageOnWeb) || other.manageOnWeb == _this.manageOnWeb)&&(identical(other.primaryCredentialId, _this.primaryCredentialId) || other.primaryCredentialId == _this.primaryCredentialId)&&(identical(other.team, _this.team) || other.team == _this.team));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SubscriptionDto;
  return Object.hash(runtimeType,_this.plan,_this.billingEnabled,_this.status,_this.limits,_this.features,_this.source,_this.productId,_this.periodEnd,_this.willRenew,_this.manageOnWeb,_this.primaryCredentialId,_this.team);
}

@override
String toString() {
  final _this = this as SubscriptionDto;
  return 'SubscriptionDto(plan: ${_this.plan}, billingEnabled: ${_this.billingEnabled}, status: ${_this.status}, limits: ${_this.limits}, features: ${_this.features}, source: ${_this.source}, productId: ${_this.productId}, periodEnd: ${_this.periodEnd}, willRenew: ${_this.willRenew}, manageOnWeb: ${_this.manageOnWeb}, primaryCredentialId: ${_this.primaryCredentialId}, team: ${_this.team})';
}


}

/// @nodoc
abstract mixin class $SubscriptionDtoCopyWith<$Res>  {
  factory $SubscriptionDtoCopyWith(SubscriptionDto value, $Res Function(SubscriptionDto) _then) = _$SubscriptionDtoCopyWithImpl;
@useResult
$Res call({
 String plan, bool billingEnabled, String status, PlanLimitsDto limits, PlanFeaturesDto features, String? source, String? productId, String? periodEnd, bool willRenew, bool manageOnWeb, String? primaryCredentialId, TeamMembershipDto? team
});


$PlanLimitsDtoCopyWith<$Res> get limits;$PlanFeaturesDtoCopyWith<$Res> get features;$TeamMembershipDtoCopyWith<$Res>? get team;

}
/// @nodoc
class _$SubscriptionDtoCopyWithImpl<$Res>
    implements $SubscriptionDtoCopyWith<$Res> {
  _$SubscriptionDtoCopyWithImpl(this._self, this._then);

  final SubscriptionDto _self;
  final $Res Function(SubscriptionDto) _then;

/// Create a copy of SubscriptionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plan = null,Object? billingEnabled = null,Object? status = null,Object? limits = null,Object? features = null,Object? source = freezed,Object? productId = freezed,Object? periodEnd = freezed,Object? willRenew = null,Object? manageOnWeb = null,Object? primaryCredentialId = freezed,Object? team = freezed,}) {
  return _then(SubscriptionDto(
plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as String,billingEnabled: null == billingEnabled ? _self.billingEnabled : billingEnabled // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,limits: null == limits ? _self.limits : limits // ignore: cast_nullable_to_non_nullable
as PlanLimitsDto,features: null == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as PlanFeaturesDto,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,productId: freezed == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String?,periodEnd: freezed == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as String?,willRenew: null == willRenew ? _self.willRenew : willRenew // ignore: cast_nullable_to_non_nullable
as bool,manageOnWeb: null == manageOnWeb ? _self.manageOnWeb : manageOnWeb // ignore: cast_nullable_to_non_nullable
as bool,primaryCredentialId: freezed == primaryCredentialId ? _self.primaryCredentialId : primaryCredentialId // ignore: cast_nullable_to_non_nullable
as String?,team: freezed == team ? _self.team : team // ignore: cast_nullable_to_non_nullable
as TeamMembershipDto?,
  ));
}
/// Create a copy of SubscriptionDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlanLimitsDtoCopyWith<$Res> get limits {
  
  return $PlanLimitsDtoCopyWith<$Res>(_self.limits, (value) {
    return _then(_self.copyWith(limits: value));
  });
}/// Create a copy of SubscriptionDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlanFeaturesDtoCopyWith<$Res> get features {
  
  return $PlanFeaturesDtoCopyWith<$Res>(_self.features, (value) {
    return _then(_self.copyWith(features: value));
  });
}/// Create a copy of SubscriptionDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TeamMembershipDtoCopyWith<$Res>? get team {
    if (_self.team == null) {
    return null;
  }

  return $TeamMembershipDtoCopyWith<$Res>(_self.team!, (value) {
    return _then(_self.copyWith(team: value));
  });
}
}


/// Adds pattern-matching-related methods to [SubscriptionDto].
extension SubscriptionDtoPatterns on SubscriptionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubscriptionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubscriptionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubscriptionDto value)  $default,){
final _that = this;
switch (_that) {
case _SubscriptionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubscriptionDto value)?  $default,){
final _that = this;
switch (_that) {
case _SubscriptionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String plan,  bool billingEnabled,  String status,  PlanLimitsDto limits,  PlanFeaturesDto features,  String? source,  String? productId,  String? periodEnd,  bool willRenew,  bool manageOnWeb,  String? primaryCredentialId,  TeamMembershipDto? team)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubscriptionDto() when $default != null:
return $default(_that.plan,_that.billingEnabled,_that.status,_that.limits,_that.features,_that.source,_that.productId,_that.periodEnd,_that.willRenew,_that.manageOnWeb,_that.primaryCredentialId,_that.team);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String plan,  bool billingEnabled,  String status,  PlanLimitsDto limits,  PlanFeaturesDto features,  String? source,  String? productId,  String? periodEnd,  bool willRenew,  bool manageOnWeb,  String? primaryCredentialId,  TeamMembershipDto? team)  $default,) {final _that = this;
switch (_that) {
case _SubscriptionDto():
return $default(_that.plan,_that.billingEnabled,_that.status,_that.limits,_that.features,_that.source,_that.productId,_that.periodEnd,_that.willRenew,_that.manageOnWeb,_that.primaryCredentialId,_that.team);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String plan,  bool billingEnabled,  String status,  PlanLimitsDto limits,  PlanFeaturesDto features,  String? source,  String? productId,  String? periodEnd,  bool willRenew,  bool manageOnWeb,  String? primaryCredentialId,  TeamMembershipDto? team)?  $default,) {final _that = this;
switch (_that) {
case _SubscriptionDto() when $default != null:
return $default(_that.plan,_that.billingEnabled,_that.status,_that.limits,_that.features,_that.source,_that.productId,_that.periodEnd,_that.willRenew,_that.manageOnWeb,_that.primaryCredentialId,_that.team);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubscriptionDto implements SubscriptionDto {
  const _SubscriptionDto({required this.plan, required this.billingEnabled, required this.status, required this.limits, required this.features, this.source, this.productId, this.periodEnd, this.willRenew = false, this.manageOnWeb = false, this.primaryCredentialId, this.team});
  factory _SubscriptionDto.fromJson(Map<String, dynamic> json) => _$SubscriptionDtoFromJson(json);

@override final  String plan;
@override final  bool billingEnabled;
@override final  String status;
@override final  PlanLimitsDto limits;
@override final  PlanFeaturesDto features;
@override final  String? source;
@override final  String? productId;
@override final  String? periodEnd;
@override@JsonKey() final  bool willRenew;
@override@JsonKey() final  bool manageOnWeb;
@override final  String? primaryCredentialId;
@override final  TeamMembershipDto? team;

/// Create a copy of SubscriptionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionDtoCopyWith<_SubscriptionDto> get copyWith => __$SubscriptionDtoCopyWithImpl<_SubscriptionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubscriptionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubscriptionDto&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.billingEnabled, billingEnabled) || other.billingEnabled == billingEnabled)&&(identical(other.status, status) || other.status == status)&&(identical(other.limits, limits) || other.limits == limits)&&(identical(other.features, features) || other.features == features)&&(identical(other.source, source) || other.source == source)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd)&&(identical(other.willRenew, willRenew) || other.willRenew == willRenew)&&(identical(other.manageOnWeb, manageOnWeb) || other.manageOnWeb == manageOnWeb)&&(identical(other.primaryCredentialId, primaryCredentialId) || other.primaryCredentialId == primaryCredentialId)&&(identical(other.team, team) || other.team == team));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,plan,billingEnabled,status,limits,features,source,productId,periodEnd,willRenew,manageOnWeb,primaryCredentialId,team);
}

@override
String toString() {
    return 'SubscriptionDto(plan: $plan, billingEnabled: $billingEnabled, status: $status, limits: $limits, features: $features, source: $source, productId: $productId, periodEnd: $periodEnd, willRenew: $willRenew, manageOnWeb: $manageOnWeb, primaryCredentialId: $primaryCredentialId, team: $team)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionDtoCopyWith<$Res> implements $SubscriptionDtoCopyWith<$Res> {
  factory _$SubscriptionDtoCopyWith(_SubscriptionDto value, $Res Function(_SubscriptionDto) _then) = __$SubscriptionDtoCopyWithImpl;
@override @useResult
$Res call({
 String plan, bool billingEnabled, String status, PlanLimitsDto limits, PlanFeaturesDto features, String? source, String? productId, String? periodEnd, bool willRenew, bool manageOnWeb, String? primaryCredentialId, TeamMembershipDto? team
});


@override $PlanLimitsDtoCopyWith<$Res> get limits;@override $PlanFeaturesDtoCopyWith<$Res> get features;@override $TeamMembershipDtoCopyWith<$Res>? get team;

}
/// @nodoc
class __$SubscriptionDtoCopyWithImpl<$Res>
    implements _$SubscriptionDtoCopyWith<$Res> {
  __$SubscriptionDtoCopyWithImpl(this._self, this._then);

  final _SubscriptionDto _self;
  final $Res Function(_SubscriptionDto) _then;

/// Create a copy of SubscriptionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? plan = null,Object? billingEnabled = null,Object? status = null,Object? limits = null,Object? features = null,Object? source = freezed,Object? productId = freezed,Object? periodEnd = freezed,Object? willRenew = null,Object? manageOnWeb = null,Object? primaryCredentialId = freezed,Object? team = freezed,}) {
  return _then(_SubscriptionDto(
plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as String,billingEnabled: null == billingEnabled ? _self.billingEnabled : billingEnabled // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,limits: null == limits ? _self.limits : limits // ignore: cast_nullable_to_non_nullable
as PlanLimitsDto,features: null == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as PlanFeaturesDto,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,productId: freezed == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String?,periodEnd: freezed == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as String?,willRenew: null == willRenew ? _self.willRenew : willRenew // ignore: cast_nullable_to_non_nullable
as bool,manageOnWeb: null == manageOnWeb ? _self.manageOnWeb : manageOnWeb // ignore: cast_nullable_to_non_nullable
as bool,primaryCredentialId: freezed == primaryCredentialId ? _self.primaryCredentialId : primaryCredentialId // ignore: cast_nullable_to_non_nullable
as String?,team: freezed == team ? _self.team : team // ignore: cast_nullable_to_non_nullable
as TeamMembershipDto?,
  ));
}

/// Create a copy of SubscriptionDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlanLimitsDtoCopyWith<$Res> get limits {
  
  return $PlanLimitsDtoCopyWith<$Res>(_self.limits, (value) {
    return _then(_self.copyWith(limits: value));
  });
}/// Create a copy of SubscriptionDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlanFeaturesDtoCopyWith<$Res> get features {
  
  return $PlanFeaturesDtoCopyWith<$Res>(_self.features, (value) {
    return _then(_self.copyWith(features: value));
  });
}/// Create a copy of SubscriptionDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TeamMembershipDtoCopyWith<$Res>? get team {
    if (_self.team == null) {
    return null;
  }

  return $TeamMembershipDtoCopyWith<$Res>(_self.team!, (value) {
    return _then(_self.copyWith(team: value));
  });
}
}


/// @nodoc
mixin _$TeamMembershipDto {

 String get id; String get name; String get role; bool get active;
/// Create a copy of TeamMembershipDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamMembershipDtoCopyWith<TeamMembershipDto> get copyWith => _$TeamMembershipDtoCopyWithImpl<TeamMembershipDto>(this as TeamMembershipDto, _$identity);

  /// Serializes this TeamMembershipDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TeamMembershipDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeamMembershipDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.active, _this.active) || other.active == _this.active));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TeamMembershipDto;
  return Object.hash(runtimeType,_this.id,_this.name,_this.role,_this.active);
}

@override
String toString() {
  final _this = this as TeamMembershipDto;
  return 'TeamMembershipDto(id: ${_this.id}, name: ${_this.name}, role: ${_this.role}, active: ${_this.active})';
}


}

/// @nodoc
abstract mixin class $TeamMembershipDtoCopyWith<$Res>  {
  factory $TeamMembershipDtoCopyWith(TeamMembershipDto value, $Res Function(TeamMembershipDto) _then) = _$TeamMembershipDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String role, bool active
});




}
/// @nodoc
class _$TeamMembershipDtoCopyWithImpl<$Res>
    implements $TeamMembershipDtoCopyWith<$Res> {
  _$TeamMembershipDtoCopyWithImpl(this._self, this._then);

  final TeamMembershipDto _self;
  final $Res Function(TeamMembershipDto) _then;

/// Create a copy of TeamMembershipDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? role = null,Object? active = null,}) {
  return _then(TeamMembershipDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TeamMembershipDto].
extension TeamMembershipDtoPatterns on TeamMembershipDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeamMembershipDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeamMembershipDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeamMembershipDto value)  $default,){
final _that = this;
switch (_that) {
case _TeamMembershipDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeamMembershipDto value)?  $default,){
final _that = this;
switch (_that) {
case _TeamMembershipDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String role,  bool active)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeamMembershipDto() when $default != null:
return $default(_that.id,_that.name,_that.role,_that.active);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String role,  bool active)  $default,) {final _that = this;
switch (_that) {
case _TeamMembershipDto():
return $default(_that.id,_that.name,_that.role,_that.active);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String role,  bool active)?  $default,) {final _that = this;
switch (_that) {
case _TeamMembershipDto() when $default != null:
return $default(_that.id,_that.name,_that.role,_that.active);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TeamMembershipDto implements TeamMembershipDto {
  const _TeamMembershipDto({required this.id, required this.name, required this.role, this.active = false});
  factory _TeamMembershipDto.fromJson(Map<String, dynamic> json) => _$TeamMembershipDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  String role;
@override@JsonKey() final  bool active;

/// Create a copy of TeamMembershipDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamMembershipDtoCopyWith<_TeamMembershipDto> get copyWith => __$TeamMembershipDtoCopyWithImpl<_TeamMembershipDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TeamMembershipDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeamMembershipDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.role, role) || other.role == role)&&(identical(other.active, active) || other.active == active));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,role,active);
}

@override
String toString() {
    return 'TeamMembershipDto(id: $id, name: $name, role: $role, active: $active)';
}


}

/// @nodoc
abstract mixin class _$TeamMembershipDtoCopyWith<$Res> implements $TeamMembershipDtoCopyWith<$Res> {
  factory _$TeamMembershipDtoCopyWith(_TeamMembershipDto value, $Res Function(_TeamMembershipDto) _then) = __$TeamMembershipDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String role, bool active
});




}
/// @nodoc
class __$TeamMembershipDtoCopyWithImpl<$Res>
    implements _$TeamMembershipDtoCopyWith<$Res> {
  __$TeamMembershipDtoCopyWithImpl(this._self, this._then);

  final _TeamMembershipDto _self;
  final $Res Function(_TeamMembershipDto) _then;

/// Create a copy of TeamMembershipDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? role = null,Object? active = null,}) {
  return _then(_TeamMembershipDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$PlanLimitsDto {

 int? get maxCredentialsTotal; int? get maxCredentialsPerTool; int? get maxPinnedJobs;
/// Create a copy of PlanLimitsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanLimitsDtoCopyWith<PlanLimitsDto> get copyWith => _$PlanLimitsDtoCopyWithImpl<PlanLimitsDto>(this as PlanLimitsDto, _$identity);

  /// Serializes this PlanLimitsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlanLimitsDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanLimitsDto&&(identical(other.maxCredentialsTotal, _this.maxCredentialsTotal) || other.maxCredentialsTotal == _this.maxCredentialsTotal)&&(identical(other.maxCredentialsPerTool, _this.maxCredentialsPerTool) || other.maxCredentialsPerTool == _this.maxCredentialsPerTool)&&(identical(other.maxPinnedJobs, _this.maxPinnedJobs) || other.maxPinnedJobs == _this.maxPinnedJobs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlanLimitsDto;
  return Object.hash(runtimeType,_this.maxCredentialsTotal,_this.maxCredentialsPerTool,_this.maxPinnedJobs);
}

@override
String toString() {
  final _this = this as PlanLimitsDto;
  return 'PlanLimitsDto(maxCredentialsTotal: ${_this.maxCredentialsTotal}, maxCredentialsPerTool: ${_this.maxCredentialsPerTool}, maxPinnedJobs: ${_this.maxPinnedJobs})';
}


}

/// @nodoc
abstract mixin class $PlanLimitsDtoCopyWith<$Res>  {
  factory $PlanLimitsDtoCopyWith(PlanLimitsDto value, $Res Function(PlanLimitsDto) _then) = _$PlanLimitsDtoCopyWithImpl;
@useResult
$Res call({
 int? maxCredentialsTotal, int? maxCredentialsPerTool, int? maxPinnedJobs
});




}
/// @nodoc
class _$PlanLimitsDtoCopyWithImpl<$Res>
    implements $PlanLimitsDtoCopyWith<$Res> {
  _$PlanLimitsDtoCopyWithImpl(this._self, this._then);

  final PlanLimitsDto _self;
  final $Res Function(PlanLimitsDto) _then;

/// Create a copy of PlanLimitsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? maxCredentialsTotal = freezed,Object? maxCredentialsPerTool = freezed,Object? maxPinnedJobs = freezed,}) {
  return _then(PlanLimitsDto(
maxCredentialsTotal: freezed == maxCredentialsTotal ? _self.maxCredentialsTotal : maxCredentialsTotal // ignore: cast_nullable_to_non_nullable
as int?,maxCredentialsPerTool: freezed == maxCredentialsPerTool ? _self.maxCredentialsPerTool : maxCredentialsPerTool // ignore: cast_nullable_to_non_nullable
as int?,maxPinnedJobs: freezed == maxPinnedJobs ? _self.maxPinnedJobs : maxPinnedJobs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanLimitsDto].
extension PlanLimitsDtoPatterns on PlanLimitsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanLimitsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanLimitsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanLimitsDto value)  $default,){
final _that = this;
switch (_that) {
case _PlanLimitsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanLimitsDto value)?  $default,){
final _that = this;
switch (_that) {
case _PlanLimitsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? maxCredentialsTotal,  int? maxCredentialsPerTool,  int? maxPinnedJobs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanLimitsDto() when $default != null:
return $default(_that.maxCredentialsTotal,_that.maxCredentialsPerTool,_that.maxPinnedJobs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? maxCredentialsTotal,  int? maxCredentialsPerTool,  int? maxPinnedJobs)  $default,) {final _that = this;
switch (_that) {
case _PlanLimitsDto():
return $default(_that.maxCredentialsTotal,_that.maxCredentialsPerTool,_that.maxPinnedJobs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? maxCredentialsTotal,  int? maxCredentialsPerTool,  int? maxPinnedJobs)?  $default,) {final _that = this;
switch (_that) {
case _PlanLimitsDto() when $default != null:
return $default(_that.maxCredentialsTotal,_that.maxCredentialsPerTool,_that.maxPinnedJobs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlanLimitsDto implements PlanLimitsDto {
  const _PlanLimitsDto({this.maxCredentialsTotal, this.maxCredentialsPerTool, this.maxPinnedJobs});
  factory _PlanLimitsDto.fromJson(Map<String, dynamic> json) => _$PlanLimitsDtoFromJson(json);

@override final  int? maxCredentialsTotal;
@override final  int? maxCredentialsPerTool;
@override final  int? maxPinnedJobs;

/// Create a copy of PlanLimitsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanLimitsDtoCopyWith<_PlanLimitsDto> get copyWith => __$PlanLimitsDtoCopyWithImpl<_PlanLimitsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlanLimitsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanLimitsDto&&(identical(other.maxCredentialsTotal, maxCredentialsTotal) || other.maxCredentialsTotal == maxCredentialsTotal)&&(identical(other.maxCredentialsPerTool, maxCredentialsPerTool) || other.maxCredentialsPerTool == maxCredentialsPerTool)&&(identical(other.maxPinnedJobs, maxPinnedJobs) || other.maxPinnedJobs == maxPinnedJobs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,maxCredentialsTotal,maxCredentialsPerTool,maxPinnedJobs);
}

@override
String toString() {
    return 'PlanLimitsDto(maxCredentialsTotal: $maxCredentialsTotal, maxCredentialsPerTool: $maxCredentialsPerTool, maxPinnedJobs: $maxPinnedJobs)';
}


}

/// @nodoc
abstract mixin class _$PlanLimitsDtoCopyWith<$Res> implements $PlanLimitsDtoCopyWith<$Res> {
  factory _$PlanLimitsDtoCopyWith(_PlanLimitsDto value, $Res Function(_PlanLimitsDto) _then) = __$PlanLimitsDtoCopyWithImpl;
@override @useResult
$Res call({
 int? maxCredentialsTotal, int? maxCredentialsPerTool, int? maxPinnedJobs
});




}
/// @nodoc
class __$PlanLimitsDtoCopyWithImpl<$Res>
    implements _$PlanLimitsDtoCopyWith<$Res> {
  __$PlanLimitsDtoCopyWithImpl(this._self, this._then);

  final _PlanLimitsDto _self;
  final $Res Function(_PlanLimitsDto) _then;

/// Create a copy of PlanLimitsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? maxCredentialsTotal = freezed,Object? maxCredentialsPerTool = freezed,Object? maxPinnedJobs = freezed,}) {
  return _then(_PlanLimitsDto(
maxCredentialsTotal: freezed == maxCredentialsTotal ? _self.maxCredentialsTotal : maxCredentialsTotal // ignore: cast_nullable_to_non_nullable
as int?,maxCredentialsPerTool: freezed == maxCredentialsPerTool ? _self.maxCredentialsPerTool : maxCredentialsPerTool // ignore: cast_nullable_to_non_nullable
as int?,maxPinnedJobs: freezed == maxPinnedJobs ? _self.maxPinnedJobs : maxPinnedJobs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$PlanFeaturesDto {

 bool get multiTool; bool get backgroundWatch; bool get homeWidget; bool get insights;
/// Create a copy of PlanFeaturesDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanFeaturesDtoCopyWith<PlanFeaturesDto> get copyWith => _$PlanFeaturesDtoCopyWithImpl<PlanFeaturesDto>(this as PlanFeaturesDto, _$identity);

  /// Serializes this PlanFeaturesDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlanFeaturesDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanFeaturesDto&&(identical(other.multiTool, _this.multiTool) || other.multiTool == _this.multiTool)&&(identical(other.backgroundWatch, _this.backgroundWatch) || other.backgroundWatch == _this.backgroundWatch)&&(identical(other.homeWidget, _this.homeWidget) || other.homeWidget == _this.homeWidget)&&(identical(other.insights, _this.insights) || other.insights == _this.insights));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlanFeaturesDto;
  return Object.hash(runtimeType,_this.multiTool,_this.backgroundWatch,_this.homeWidget,_this.insights);
}

@override
String toString() {
  final _this = this as PlanFeaturesDto;
  return 'PlanFeaturesDto(multiTool: ${_this.multiTool}, backgroundWatch: ${_this.backgroundWatch}, homeWidget: ${_this.homeWidget}, insights: ${_this.insights})';
}


}

/// @nodoc
abstract mixin class $PlanFeaturesDtoCopyWith<$Res>  {
  factory $PlanFeaturesDtoCopyWith(PlanFeaturesDto value, $Res Function(PlanFeaturesDto) _then) = _$PlanFeaturesDtoCopyWithImpl;
@useResult
$Res call({
 bool multiTool, bool backgroundWatch, bool homeWidget, bool insights
});




}
/// @nodoc
class _$PlanFeaturesDtoCopyWithImpl<$Res>
    implements $PlanFeaturesDtoCopyWith<$Res> {
  _$PlanFeaturesDtoCopyWithImpl(this._self, this._then);

  final PlanFeaturesDto _self;
  final $Res Function(PlanFeaturesDto) _then;

/// Create a copy of PlanFeaturesDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? multiTool = null,Object? backgroundWatch = null,Object? homeWidget = null,Object? insights = null,}) {
  return _then(PlanFeaturesDto(
multiTool: null == multiTool ? _self.multiTool : multiTool // ignore: cast_nullable_to_non_nullable
as bool,backgroundWatch: null == backgroundWatch ? _self.backgroundWatch : backgroundWatch // ignore: cast_nullable_to_non_nullable
as bool,homeWidget: null == homeWidget ? _self.homeWidget : homeWidget // ignore: cast_nullable_to_non_nullable
as bool,insights: null == insights ? _self.insights : insights // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanFeaturesDto].
extension PlanFeaturesDtoPatterns on PlanFeaturesDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanFeaturesDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanFeaturesDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanFeaturesDto value)  $default,){
final _that = this;
switch (_that) {
case _PlanFeaturesDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanFeaturesDto value)?  $default,){
final _that = this;
switch (_that) {
case _PlanFeaturesDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool multiTool,  bool backgroundWatch,  bool homeWidget,  bool insights)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanFeaturesDto() when $default != null:
return $default(_that.multiTool,_that.backgroundWatch,_that.homeWidget,_that.insights);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool multiTool,  bool backgroundWatch,  bool homeWidget,  bool insights)  $default,) {final _that = this;
switch (_that) {
case _PlanFeaturesDto():
return $default(_that.multiTool,_that.backgroundWatch,_that.homeWidget,_that.insights);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool multiTool,  bool backgroundWatch,  bool homeWidget,  bool insights)?  $default,) {final _that = this;
switch (_that) {
case _PlanFeaturesDto() when $default != null:
return $default(_that.multiTool,_that.backgroundWatch,_that.homeWidget,_that.insights);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlanFeaturesDto implements PlanFeaturesDto {
  const _PlanFeaturesDto({this.multiTool = false, this.backgroundWatch = false, this.homeWidget = false, this.insights = false});
  factory _PlanFeaturesDto.fromJson(Map<String, dynamic> json) => _$PlanFeaturesDtoFromJson(json);

@override@JsonKey() final  bool multiTool;
@override@JsonKey() final  bool backgroundWatch;
@override@JsonKey() final  bool homeWidget;
@override@JsonKey() final  bool insights;

/// Create a copy of PlanFeaturesDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanFeaturesDtoCopyWith<_PlanFeaturesDto> get copyWith => __$PlanFeaturesDtoCopyWithImpl<_PlanFeaturesDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlanFeaturesDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanFeaturesDto&&(identical(other.multiTool, multiTool) || other.multiTool == multiTool)&&(identical(other.backgroundWatch, backgroundWatch) || other.backgroundWatch == backgroundWatch)&&(identical(other.homeWidget, homeWidget) || other.homeWidget == homeWidget)&&(identical(other.insights, insights) || other.insights == insights));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,multiTool,backgroundWatch,homeWidget,insights);
}

@override
String toString() {
    return 'PlanFeaturesDto(multiTool: $multiTool, backgroundWatch: $backgroundWatch, homeWidget: $homeWidget, insights: $insights)';
}


}

/// @nodoc
abstract mixin class _$PlanFeaturesDtoCopyWith<$Res> implements $PlanFeaturesDtoCopyWith<$Res> {
  factory _$PlanFeaturesDtoCopyWith(_PlanFeaturesDto value, $Res Function(_PlanFeaturesDto) _then) = __$PlanFeaturesDtoCopyWithImpl;
@override @useResult
$Res call({
 bool multiTool, bool backgroundWatch, bool homeWidget, bool insights
});




}
/// @nodoc
class __$PlanFeaturesDtoCopyWithImpl<$Res>
    implements _$PlanFeaturesDtoCopyWith<$Res> {
  __$PlanFeaturesDtoCopyWithImpl(this._self, this._then);

  final _PlanFeaturesDto _self;
  final $Res Function(_PlanFeaturesDto) _then;

/// Create a copy of PlanFeaturesDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? multiTool = null,Object? backgroundWatch = null,Object? homeWidget = null,Object? insights = null,}) {
  return _then(_PlanFeaturesDto(
multiTool: null == multiTool ? _self.multiTool : multiTool // ignore: cast_nullable_to_non_nullable
as bool,backgroundWatch: null == backgroundWatch ? _self.backgroundWatch : backgroundWatch // ignore: cast_nullable_to_non_nullable
as bool,homeWidget: null == homeWidget ? _self.homeWidget : homeWidget // ignore: cast_nullable_to_non_nullable
as bool,insights: null == insights ? _self.insights : insights // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
