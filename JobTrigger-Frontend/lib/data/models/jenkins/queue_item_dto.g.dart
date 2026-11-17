// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QueueItemDto _$QueueItemDtoFromJson(Map<String, dynamic> json) =>
    _QueueItemDto(
      why: json['why'] as String?,
      cancelled: json['cancelled'] as bool? ?? false,
      executable: json['executable'] == null
          ? null
          : QueueExecutableDto.fromJson(
              json['executable'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$QueueItemDtoToJson(_QueueItemDto instance) =>
    <String, dynamic>{
      'why': instance.why,
      'cancelled': instance.cancelled,
      'executable': instance.executable,
    };

_QueueExecutableDto _$QueueExecutableDtoFromJson(Map<String, dynamic> json) =>
    _QueueExecutableDto(
      number: (json['number'] as num).toInt(),
      url: json['url'] as String,
    );

Map<String, dynamic> _$QueueExecutableDtoToJson(_QueueExecutableDto instance) =>
    <String, dynamic>{'number': instance.number, 'url': instance.url};
