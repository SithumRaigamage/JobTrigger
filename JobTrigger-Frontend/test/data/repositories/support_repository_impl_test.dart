import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/support_repository_impl.dart';
import 'package:job_trigger/domain/support/support_area.dart';
import 'package:job_trigger/domain/support/support_category.dart';
import 'package:job_trigger/domain/support/support_impact.dart';
import 'package:job_trigger/domain/support/support_screenshot.dart';
import 'package:job_trigger/domain/support/support_ticket.dart';

class _CaptureAdapter implements HttpClientAdapter {
  Object? sent;
  String? path;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.path;
    sent = options.data;
    final id = DateTime(2026, 11, 23).millisecondsSinceEpoch.toString();
    return ResponseBody.fromString(
      jsonEncode({
        'ticket': {
          'id': id,
          'category': 'bug',
          'subject': 'Blank log',
          'message': 'Nothing shows.',
          'areas': ['jenkins', 'phone'],
          'impact': 'blocked',
          'screenshotCount': 1,
          'status': 'open',
        },
      }),
      201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'submit sends the P31 options and maps the reply back to the domain',
    () async {
      final adapter = _CaptureAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = adapter;
      final repo = SupportRepositoryImpl(dio);
      final bytes = Uint8List.fromList([
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
        1,
        2,
      ]);

      final result = await repo.submit(
        category: SupportCategory.bug,
        subject: 'Blank log',
        message: 'Nothing shows.',
        areas: const [SupportArea.jenkins, SupportArea.phone],
        impact: SupportImpact.blocked,
        screenshots: [SupportScreenshot(name: 'shot.png', bytes: bytes)],
      );

      final body = adapter.sent as Map<String, dynamic>;
      expect(adapter.path, '/api/support/tickets');
      expect(body['areas'], ['jenkins', 'phone']);
      expect(body['impact'], 'blocked');
      expect((body['screenshots'] as List).single['data'], base64Encode(bytes));
      expect(body, isNot(contains('screenshotPath')));

      final ticket = (result as Ok<SupportTicket, AppFailure>).value;
      expect(ticket.areas, [SupportArea.jenkins, SupportArea.phone]);
      expect(ticket.impact, SupportImpact.blocked);
      expect(ticket.screenshotCount, 1);
      expect(ticket.category, SupportCategory.bug);
    },
  );
}
