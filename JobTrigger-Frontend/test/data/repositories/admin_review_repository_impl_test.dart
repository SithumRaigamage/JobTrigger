import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/demo/demo_admin_review_repository.dart';
import 'package:job_trigger/data/repositories/admin_review_repository_impl.dart';
import 'package:job_trigger/domain/admin_review/admin_student_application.dart';
import 'package:job_trigger/domain/student/student_application.dart';

/// Answers every request with [status] and a JSON [body], or raw [bytes].
class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, {this.body, this.bytes, this.contentType});

  final int status;
  final Object? body;
  final List<int>? bytes;
  final String? contentType;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (bytes != null) {
      return ResponseBody.fromBytes(
        bytes!,
        status,
        headers: {
          Headers.contentTypeHeader: [contentType ?? 'image/png'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body ?? {}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

AdminReviewRepositoryImpl _repo(_Adapter adapter) => AdminReviewRepositoryImpl(
  Dio(BaseOptions(baseUrl: 'http://backend.test'))..httpClientAdapter = adapter,
);

const _item = {
  'id': 'e1',
  'userId': 'u1',
  'accountEmail': 'kasun@example.com',
  'method': 'email',
  'status': 'approved',
  'fullName': null,
  'universityEmail': 'kasun@uom.ac.lk',
  'submittedAt': '2026-11-20T10:00:00.000Z',
  'emailVerifiedAt': '2026-11-20T10:05:00.000Z',
  'reviewedAt': '2026-11-22T08:00:00.000Z',
  'reviewedBy': 'a1',
  'reviewedByEmail': 'developer@jobtrigger.app',
  'approvedAt': '2026-11-22T08:00:00.000Z',
  'expiresAt': '2027-11-22T08:00:00.000Z',
  'rejectionReason': null,
  'documentMime': null,
  'documentSize': null,
  'hasDocument': false,
  'documentDeleted': false,
  'documentDeleteAt': null,
};

/// [Result] has no value equality: compare what it holds.
Object? _okValue(Result<Object?, AppFailure> result) =>
    (result as Ok<Object?, AppFailure>).value;

void main() {
  group('hasAccess (US-STU-02)', () {
    test('a super admin is true', () async {
      final adapter = _Adapter(200, body: {'role': 'superAdmin'});
      expect(_okValue(await _repo(adapter).hasAccess()), true);
      expect(adapter.requests.single.path, '/api/admin/students/access');
    });

    test("everyone else's plain 404 is false, not a failure", () async {
      final result = await _repo(
        _Adapter(404, body: {'message': 'Not found'}),
      ).hasAccess();
      expect(_okValue(result), false);
    });

    test(
      'a network failure is a failure (the caller treats it as no)',
      () async {
        final result = await _repo(_Adapter(500, body: {})).hasAccess();
        expect(result, isA<Err<bool, AppFailure>>());
      },
    );
  });

  test(
    'list sends the filter and maps both methods with review fields',
    () async {
      final adapter = _Adapter(
        200,
        body: {
          'items': [
            _item,
            {
              ..._item,
              'id': 'd1',
              'method': 'document',
              'status': 'pending',
              'fullName': 'Amal Fernando',
              'universityEmail': null,
              'emailVerifiedAt': null,
              'reviewedAt': null,
              'reviewedByEmail': null,
              'documentMime': 'application/pdf',
              'hasDocument': true,
            },
          ],
        },
      );
      final result = await _repo(adapter).list(AdminStatusFilter.expired);
      final items =
          (result as Ok<List<AdminStudentApplication>, AppFailure>).value;
      expect(adapter.requests.single.path, '/api/admin/students');
      expect(adapter.requests.single.queryParameters, {'status': 'expired'});
      expect(items.first.method, StudentMethod.email);
      expect(items.first.status, StudentStatus.approved);
      expect(items.first.reviewedByEmail, 'developer@jobtrigger.app');
      expect(items.first.emailVerifiedAt, DateTime.utc(2026, 11, 20, 10, 5));
      expect(items.first.title, 'kasun@uom.ac.lk');
      expect(items.last.method, StudentMethod.document);
      expect(items.last.title, 'Amal Fernando');
      expect(items.last.hasDocument, isTrue);
    },
  );

  test('an older backend without the review fields still parses', () async {
    final older = Map<String, Object?>.from(_item)
      ..remove('emailVerifiedAt')
      ..remove('reviewedByEmail');
    final result = await _repo(_Adapter(200, body: older)).get('e1');
    final item = (result as Ok<AdminStudentApplication, AppFailure>).value;
    expect(item.reviewedByEmail, isNull);
    expect(item.emailVerifiedAt, isNull);
  });

  group('document (US-STU-02)', () {
    test('returns the bytes and the type, in memory', () async {
      final png = [0x89, 0x50, 0x4e, 0x47, 1, 2, 3];
      final adapter = _Adapter(200, bytes: png, contentType: 'image/png');
      final result = await _repo(adapter).document('d1');
      final doc = (result as Ok<AdminStudentDocument?, AppFailure>).value!;
      expect(doc.mime, 'image/png');
      expect(doc.bytes, png);
      expect(doc.isImage, isTrue);
      expect(adapter.requests.single.path, '/api/admin/students/d1/document');
      expect(adapter.requests.single.responseType, ResponseType.bytes);
    });

    test('a PDF keeps its type', () async {
      final result = await _repo(
        _Adapter(
          200,
          bytes: utf8.encode('%PDF-1.4'),
          contentType: 'application/pdf',
        ),
      ).document('d1');
      expect(
        (result as Ok<AdminStudentDocument?, AppFailure>).value!.isPdf,
        isTrue,
      );
    });

    test('a deleted document (410) is Ok(null)', () async {
      final result = await _repo(
        _Adapter(410, body: {'message': 'deleted'}),
      ).document('d1');
      expect(_okValue(result), isNull);
    });
  });

  test('approve and reject post to the id with the trimmed reason', () async {
    final adapter = _Adapter(200, body: _item);
    final repo = _repo(adapter);
    await repo.approve('e1');
    await repo.reject('e1', 'Not a student address');
    expect(adapter.requests[0].method, 'POST');
    expect(adapter.requests[0].path, '/api/admin/students/e1/approve');
    expect(adapter.requests[1].path, '/api/admin/students/e1/reject');
    expect(adapter.requests[1].data, {'reason': 'Not a student address'});
  });

  test("a refused decision carries the backend's sentence", () async {
    final result = await _repo(
      _Adapter(
        409,
        body: {
          'code': 'email_used',
          'message':
              'That university email has already been used for a student plan.',
        },
      ),
    ).approve('e1');
    final failure = (result as Err<AdminStudentApplication, AppFailure>).error;
    expect(failure, isA<StudentRequestFailure>());
    expect(failure.message, contains('already been used'));
  });

  test('ids are encoded into the path', () async {
    final adapter = _Adapter(200, body: _item);
    await _repo(adapter).get('a/b');
    expect(adapter.requests.single.path, '/api/admin/students/a%2Fb');
  });

  test('demo mode is never an admin and sends nothing', () async {
    expect(_okValue(await demoAdminReviewRepository.hasAccess()), false);
    expect(
      await demoAdminReviewRepository.approve('x'),
      isA<Err<AdminStudentApplication, AppFailure>>(),
    );
  });
}
