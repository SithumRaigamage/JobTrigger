import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/support/support_category.dart';
import '../../../domain/support/support_ticket.dart';

part 'support_ticket_dto.freezed.dart';
part 'support_ticket_dto.g.dart';

/// Mirrors the backend's `publicTicket`
/// (`JobTrigger-Backend/controllers/supportController.js`).
@freezed
abstract class SupportTicketDto with _$SupportTicketDto {
  const factory SupportTicketDto({
    required String id,
    required String category,
    required String subject,
    @Default('') String message,
    @Default('open') String status,
    String? createdAt,
  }) = _SupportTicketDto;

  factory SupportTicketDto.fromJson(Map<String, dynamic> json) =>
      _$SupportTicketDtoFromJson(json);
}

extension SupportTicketDtoX on SupportTicketDto {
  SupportTicket toDomain() => SupportTicket(
    id: id,
    category: SupportCategory.values
        .where((value) => value.wire == category)
        .firstOrNull,
    subject: subject,
    message: message,
    status: status,
    createdAt: createdAt == null ? null : DateTime.tryParse(createdAt!),
  );
}
