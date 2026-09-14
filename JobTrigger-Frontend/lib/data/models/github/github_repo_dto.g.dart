// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_repo_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GitHubRepoDto _$GitHubRepoDtoFromJson(Map<String, dynamic> json) =>
    _GitHubRepoDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      fullName: json['full_name'] as String,
      owner: GitHubRepoOwnerDto.fromJson(json['owner'] as Map<String, dynamic>),
      private: json['private'] as bool? ?? false,
      defaultBranch: json['default_branch'] as String? ?? 'main',
    );

Map<String, dynamic> _$GitHubRepoDtoToJson(_GitHubRepoDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'full_name': instance.fullName,
      'owner': instance.owner,
      'private': instance.private,
      'default_branch': instance.defaultBranch,
    };

_GitHubRepoOwnerDto _$GitHubRepoOwnerDtoFromJson(Map<String, dynamic> json) =>
    _GitHubRepoOwnerDto(login: json['login'] as String);

Map<String, dynamic> _$GitHubRepoOwnerDtoToJson(_GitHubRepoOwnerDto instance) =>
    <String, dynamic>{'login': instance.login};
