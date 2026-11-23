import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/guard.dart';
import '../../core/error/result.dart';
import '../../core/network/backend_api_client.dart';
import '../../domain/support/support_area.dart';
import '../../domain/support/support_category.dart';
import '../../domain/support/support_diagnostics.dart';
import '../../domain/support/support_impact.dart';
import '../../domain/support/support_repository.dart';
import '../../domain/support/support_screenshot.dart';
import '../../domain/support/support_ticket.dart';
import '../demo/demo_mode_notifier.dart';
import '../models/support/support_ticket_dto.dart';

part 'support_repository_impl.g.dart';

/// The Phase 25 DTO carries the text; P31 adds these options from the same
/// JSON without changing the generated freezed shape. Image bytes are never
/// returned by the user-facing endpoint, only `screenshotCount`.
SupportTicket _ticketFromJson(Map<String, dynamic> json) {
  final ticket = SupportTicketDto.fromJson(json).toDomain();
  final areas = (json['areas'] as List<dynamic>? ?? [])
      .map((value) => SupportArea.fromWire(value as String?))
      .whereType<SupportArea>()
      .toList();
  return ticket.copyWith(
    areas: areas,
    impact: SupportImpact.fromWire(json['impact'] as String?),
    screenshotCount: (json['screenshotCount'] as num?)?.toInt() ?? 0,
  );
}

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
    List<SupportArea> areas = const [],
    SupportImpact impact = SupportImpact.minor,
    List<SupportScreenshot> screenshots = const [],
  }) => guardRequest(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/support/tickets',
      data: {
        'category': category.wire,
        'subject': subject,
        'message': message,
        if (replyEmail != null && replyEmail.isNotEmpty)
          'replyEmail': replyEmail,
        if (areas.isNotEmpty) 'areas': areas.map((area) => area.wire).toList(),
        'impact': impact.wire,
        if (screenshots.isNotEmpty)
          'screenshots': screenshots.map((shot) => shot.toJson()).toList(),
        ...?diagnostics?.toJson(),
      },
    );
    return _ticketFromJson(response.data!['ticket'] as Map<String, dynamic>);
  });

  @override
  Future<Result<List<SupportTicket>, AppFailure>> fetchMine() =>
      guardRequest(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/api/support/tickets',
        );
        final tickets = (response.data!['tickets'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(_ticketFromJson)
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
    List<SupportArea> areas = const [],
    SupportImpact impact = SupportImpact.minor,
    List<SupportScreenshot> screenshots = const [],
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
