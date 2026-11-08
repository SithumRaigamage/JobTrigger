// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'github_workflow_run_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GitHubWorkflowRunDto {

 int get id;@JsonKey(name: 'run_number') int get runNumber;// `display_title` is the commit message / PR title; `name` is the
// workflow's own name and the fallback for older responses.
@JsonKey(name: 'display_title') String? get displayTitle; String? get name; String get event; String get status; String? get conclusion;@JsonKey(name: 'head_branch') String? get headBranch;@JsonKey(name: 'created_at') String? get createdAt;@JsonKey(name: 'html_url') String get htmlUrl;@JsonKey(name: 'workflow_id') int? get workflowId;
/// Create a copy of GitHubWorkflowRunDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitHubWorkflowRunDtoCopyWith<GitHubWorkflowRunDto> get copyWith => _$GitHubWorkflowRunDtoCopyWithImpl<GitHubWorkflowRunDto>(this as GitHubWorkflowRunDto, _$identity);

  /// Serializes this GitHubWorkflowRunDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitHubWorkflowRunDto&&(identical(other.id, id) || other.id == id)&&(identical(other.runNumber, runNumber) || other.runNumber == runNumber)&&(identical(other.displayTitle, displayTitle) || other.displayTitle == displayTitle)&&(identical(other.name, name) || other.name == name)&&(identical(other.event, event) || other.event == event)&&(identical(other.status, status) || other.status == status)&&(identical(other.conclusion, conclusion) || other.conclusion == conclusion)&&(identical(other.headBranch, headBranch) || other.headBranch == headBranch)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl)&&(identical(other.workflowId, workflowId) || other.workflowId == workflowId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,runNumber,displayTitle,name,event,status,conclusion,headBranch,createdAt,htmlUrl,workflowId);

@override
String toString() {
  return 'GitHubWorkflowRunDto(id: $id, runNumber: $runNumber, displayTitle: $displayTitle, name: $name, event: $event, status: $status, conclusion: $conclusion, headBranch: $headBranch, createdAt: $createdAt, htmlUrl: $htmlUrl, workflowId: $workflowId)';
}


}

/// @nodoc
abstract mixin class $GitHubWorkflowRunDtoCopyWith<$Res>  {
  factory $GitHubWorkflowRunDtoCopyWith(GitHubWorkflowRunDto value, $Res Function(GitHubWorkflowRunDto) _then) = _$GitHubWorkflowRunDtoCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'run_number') int runNumber,@JsonKey(name: 'display_title') String? displayTitle, String? name, String event, String status, String? conclusion,@JsonKey(name: 'head_branch') String? headBranch,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'html_url') String htmlUrl,@JsonKey(name: 'workflow_id') int? workflowId
});




}
/// @nodoc
class _$GitHubWorkflowRunDtoCopyWithImpl<$Res>
    implements $GitHubWorkflowRunDtoCopyWith<$Res> {
  _$GitHubWorkflowRunDtoCopyWithImpl(this._self, this._then);

  final GitHubWorkflowRunDto _self;
  final $Res Function(GitHubWorkflowRunDto) _then;

/// Create a copy of GitHubWorkflowRunDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? runNumber = null,Object? displayTitle = freezed,Object? name = freezed,Object? event = null,Object? status = null,Object? conclusion = freezed,Object? headBranch = freezed,Object? createdAt = freezed,Object? htmlUrl = null,Object? workflowId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,runNumber: null == runNumber ? _self.runNumber : runNumber // ignore: cast_nullable_to_non_nullable
as int,displayTitle: freezed == displayTitle ? _self.displayTitle : displayTitle // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,event: null == event ? _self.event : event // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,conclusion: freezed == conclusion ? _self.conclusion : conclusion // ignore: cast_nullable_to_non_nullable
as String?,headBranch: freezed == headBranch ? _self.headBranch : headBranch // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,htmlUrl: null == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
as String,workflowId: freezed == workflowId ? _self.workflowId : workflowId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [GitHubWorkflowRunDto].
extension GitHubWorkflowRunDtoPatterns on GitHubWorkflowRunDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GitHubWorkflowRunDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GitHubWorkflowRunDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GitHubWorkflowRunDto value)  $default,){
final _that = this;
switch (_that) {
case _GitHubWorkflowRunDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GitHubWorkflowRunDto value)?  $default,){
final _that = this;
switch (_that) {
case _GitHubWorkflowRunDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'run_number')  int runNumber, @JsonKey(name: 'display_title')  String? displayTitle,  String? name,  String event,  String status,  String? conclusion, @JsonKey(name: 'head_branch')  String? headBranch, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'html_url')  String htmlUrl, @JsonKey(name: 'workflow_id')  int? workflowId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitHubWorkflowRunDto() when $default != null:
return $default(_that.id,_that.runNumber,_that.displayTitle,_that.name,_that.event,_that.status,_that.conclusion,_that.headBranch,_that.createdAt,_that.htmlUrl,_that.workflowId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'run_number')  int runNumber, @JsonKey(name: 'display_title')  String? displayTitle,  String? name,  String event,  String status,  String? conclusion, @JsonKey(name: 'head_branch')  String? headBranch, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'html_url')  String htmlUrl, @JsonKey(name: 'workflow_id')  int? workflowId)  $default,) {final _that = this;
switch (_that) {
case _GitHubWorkflowRunDto():
return $default(_that.id,_that.runNumber,_that.displayTitle,_that.name,_that.event,_that.status,_that.conclusion,_that.headBranch,_that.createdAt,_that.htmlUrl,_that.workflowId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'run_number')  int runNumber, @JsonKey(name: 'display_title')  String? displayTitle,  String? name,  String event,  String status,  String? conclusion, @JsonKey(name: 'head_branch')  String? headBranch, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'html_url')  String htmlUrl, @JsonKey(name: 'workflow_id')  int? workflowId)?  $default,) {final _that = this;
switch (_that) {
case _GitHubWorkflowRunDto() when $default != null:
return $default(_that.id,_that.runNumber,_that.displayTitle,_that.name,_that.event,_that.status,_that.conclusion,_that.headBranch,_that.createdAt,_that.htmlUrl,_that.workflowId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GitHubWorkflowRunDto implements GitHubWorkflowRunDto {
  const _GitHubWorkflowRunDto({required this.id, @JsonKey(name: 'run_number') this.runNumber = 0, @JsonKey(name: 'display_title') this.displayTitle, this.name, this.event = '', this.status = '', this.conclusion, @JsonKey(name: 'head_branch') this.headBranch, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'html_url') this.htmlUrl = '', @JsonKey(name: 'workflow_id') this.workflowId});
  factory _GitHubWorkflowRunDto.fromJson(Map<String, dynamic> json) => _$GitHubWorkflowRunDtoFromJson(json);

@override final  int id;
@override@JsonKey(name: 'run_number') final  int runNumber;
// `display_title` is the commit message / PR title; `name` is the
// workflow's own name and the fallback for older responses.
@override@JsonKey(name: 'display_title') final  String? displayTitle;
@override final  String? name;
@override@JsonKey() final  String event;
@override@JsonKey() final  String status;
@override final  String? conclusion;
@override@JsonKey(name: 'head_branch') final  String? headBranch;
@override@JsonKey(name: 'created_at') final  String? createdAt;
@override@JsonKey(name: 'html_url') final  String htmlUrl;
@override@JsonKey(name: 'workflow_id') final  int? workflowId;

/// Create a copy of GitHubWorkflowRunDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GitHubWorkflowRunDtoCopyWith<_GitHubWorkflowRunDto> get copyWith => __$GitHubWorkflowRunDtoCopyWithImpl<_GitHubWorkflowRunDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GitHubWorkflowRunDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitHubWorkflowRunDto&&(identical(other.id, id) || other.id == id)&&(identical(other.runNumber, runNumber) || other.runNumber == runNumber)&&(identical(other.displayTitle, displayTitle) || other.displayTitle == displayTitle)&&(identical(other.name, name) || other.name == name)&&(identical(other.event, event) || other.event == event)&&(identical(other.status, status) || other.status == status)&&(identical(other.conclusion, conclusion) || other.conclusion == conclusion)&&(identical(other.headBranch, headBranch) || other.headBranch == headBranch)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl)&&(identical(other.workflowId, workflowId) || other.workflowId == workflowId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,runNumber,displayTitle,name,event,status,conclusion,headBranch,createdAt,htmlUrl,workflowId);

@override
String toString() {
  return 'GitHubWorkflowRunDto(id: $id, runNumber: $runNumber, displayTitle: $displayTitle, name: $name, event: $event, status: $status, conclusion: $conclusion, headBranch: $headBranch, createdAt: $createdAt, htmlUrl: $htmlUrl, workflowId: $workflowId)';
}


}

/// @nodoc
abstract mixin class _$GitHubWorkflowRunDtoCopyWith<$Res> implements $GitHubWorkflowRunDtoCopyWith<$Res> {
  factory _$GitHubWorkflowRunDtoCopyWith(_GitHubWorkflowRunDto value, $Res Function(_GitHubWorkflowRunDto) _then) = __$GitHubWorkflowRunDtoCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'run_number') int runNumber,@JsonKey(name: 'display_title') String? displayTitle, String? name, String event, String status, String? conclusion,@JsonKey(name: 'head_branch') String? headBranch,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'html_url') String htmlUrl,@JsonKey(name: 'workflow_id') int? workflowId
});




}
/// @nodoc
class __$GitHubWorkflowRunDtoCopyWithImpl<$Res>
    implements _$GitHubWorkflowRunDtoCopyWith<$Res> {
  __$GitHubWorkflowRunDtoCopyWithImpl(this._self, this._then);

  final _GitHubWorkflowRunDto _self;
  final $Res Function(_GitHubWorkflowRunDto) _then;

/// Create a copy of GitHubWorkflowRunDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? runNumber = null,Object? displayTitle = freezed,Object? name = freezed,Object? event = null,Object? status = null,Object? conclusion = freezed,Object? headBranch = freezed,Object? createdAt = freezed,Object? htmlUrl = null,Object? workflowId = freezed,}) {
  return _then(_GitHubWorkflowRunDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,runNumber: null == runNumber ? _self.runNumber : runNumber // ignore: cast_nullable_to_non_nullable
as int,displayTitle: freezed == displayTitle ? _self.displayTitle : displayTitle // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,event: null == event ? _self.event : event // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,conclusion: freezed == conclusion ? _self.conclusion : conclusion // ignore: cast_nullable_to_non_nullable
as String?,headBranch: freezed == headBranch ? _self.headBranch : headBranch // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,htmlUrl: null == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
as String,workflowId: freezed == workflowId ? _self.workflowId : workflowId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
