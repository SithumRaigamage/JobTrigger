// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_ticket_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SupportTicketDto _$SupportTicketDtoFromJson(Map<String, dynamic> json) =>
    _SupportTicketDto(
      id: json['id'] as String,
      category: json['category'] as String,
      subject: json['subject'] as String,
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$SupportTicketDtoToJson(_SupportTicketDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category': instance.category,
      'subject': instance.subject,
      'message': instance.message,
      'status': instance.status,
      'createdAt': instance.createdAt,
    };
