import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/guard.dart';
import '../../core/error/result.dart';
import '../../core/network/backend_api_client.dart';
import '../../domain/support/support_category.dart';
import '../../domain/support/support_diagnostics.dart';
import '../../domain/support/support_repository.dart';
import '../../domain/support/support_ticket.dart';
import '../demo/demo_mode_notifier.dart';
import '../models/support/support_ticket_dto.dart';

part 'support_repository_impl.g.dart';

/// P25-05: `POST/GET /api/support/tickets`, through `guardRequest` so nothing
/// throws past the data layer (`CLAUDE.md` §5).
class SupportRepositoryImpl implements SupportRepository {
  SupportRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<SupportTicket, AppFailure>> submit({
    required SupportCategory category,
    required String subject,
    required String message,
    String? replyEmail,
    SupportDiagnostics? diagnostics,
  }) => guardRequest(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/support/tickets',
      data: {
        'category': category.wire,
        'subject': subject,
        'message': message,
        if (replyEmail != null && replyEmail.isNotEmpty)
          'replyEmail': replyEmail,
        ...?diagnostics?.toJson(),
      },
    );
    return SupportTicketDto.fromJson(
      response.data!['ticket'] as Map<String, dynamic>,
    ).toDomain();
  });

  @override
  Future<Result<List<SupportTicket>, AppFailure>> fetchMine() =>
      guardRequest(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/api/support/tickets',
        );
        final tickets = (response.data!['tickets'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(SupportTicketDto.fromJson)
            .map((dto) => dto.toDomain())
            .toList();
        return tickets;
      });
}

/// E2: demo mode never reaches the backend, and a report nobody would read
/// must not pretend to be sent.
class DemoSupportRepository implements SupportRepository {
  const DemoSupportRepository();

  @override
  Future<Result<SupportTicket, AppFailure>> submit({
    required SupportCategory category,
    required String subject,
    required String message,
    String? replyEmail,
    SupportDiagnostics? diagnostics,
  }) async => const Err(DemoUnavailableFailure());

  @override
  Future<Result<List<SupportTicket>, AppFailure>> fetchMine() async =>
      const Ok([]);
}

@riverpod
SupportRepository supportRepository(Ref ref) {
  if (ref.watch(demoModeNotifierProvider)) return const DemoSupportRepository();
  return SupportRepositoryImpl(ref.watch(dioBackendProvider));
}
