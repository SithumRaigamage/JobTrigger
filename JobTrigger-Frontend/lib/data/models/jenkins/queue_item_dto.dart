import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/jenkins/queue_item.dart';

part 'queue_item_dto.freezed.dart';
part 'queue_item_dto.g.dart';

/// `GET {queueItemUrl}api/json` — `executable` is absent while queued,
/// present once Jenkins assigns an executor.
@freezed
abstract class QueueItemDto with _$QueueItemDto {
  const factory QueueItemDto({
    String? why,
    @Default(false) bool cancelled,
    QueueExecutableDto? executable,
  }) = _QueueItemDto;

  factory QueueItemDto.fromJson(Map<String, dynamic> json) =>
      _$QueueItemDtoFromJson(json);
}

@freezed
abstract class QueueExecutableDto with _$QueueExecutableDto {
  const factory QueueExecutableDto({required int number, required String url}) =
      _QueueExecutableDto;

  factory QueueExecutableDto.fromJson(Map<String, dynamic> json) =>
      _$QueueExecutableDtoFromJson(json);
}

extension QueueItemDtoX on QueueItemDto {
  QueueItem toDomain() => QueueItem(
    why: why,
    cancelled: cancelled,
    executable: executable == null
        ? null
        : QueueExecutable(number: executable!.number, url: executable!.url),
  );
}
