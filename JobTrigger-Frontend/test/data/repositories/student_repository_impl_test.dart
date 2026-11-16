import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/demo/demo_student_repository.dart';
import 'package:job_trigger/data/repositories/student_repository_impl.dart';
import 'package:job_trigger/domain/student/student_application.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.body);

  final int status;
  final Object body;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

StudentRepositoryImpl _repo(_Adapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://backend.test'))
    ..httpClientAdapter = adapter;
  return StudentRepositoryImpl(dio);
}

void main() {
  test('status maps the backend body', () async {
    final adapter = _Adapter(200, {
      'id': 'a1',
      'method': 'document',
      'status': 'rejected',
      'rejectionReason': 'Too blurry',
      'expiresAt': null,
    });
    final result = await _repo(adapter).status();
    final app = (result as Ok<StudentApplication, AppFailure>).value;
    expect(app.status, StudentStatus.rejected);
    expect(app.method, StudentMethod.document);
    expect(app.rejectionReason, 'Too blurry');
    expect(adapter.requests.single.path, '/api/student');
  });

  test('status maps "none" and unknown values to none', () async {
    final result = await _repo(_Adapter(200, {'status': 'none'})).status();
    expect(
      (result as Ok<StudentApplication, AppFailure>).value.status,
      StudentStatus.none,
    );
  });

  test('confirmEmail sends the code and parses the approved year', () async {
    final adapter = _Adapter(200, {
      'status': 'approved',
      'method': 'email',
      'approvedAt': '2026-11-16T10:00:00.000Z',
      'expiresAt': '2027-11-16T10:00:00.000Z',
    });
    final result = await _repo(adapter).confirmEmail('123456');
    final app = (result as Ok<StudentApplication, AppFailure>).value;
    expect(app.status, StudentStatus.approved);
    expect(app.expiresAt, DateTime.utc(2027, 11, 16, 10));
    expect(adapter.requests.single.data, {'code': '123456'});
    expect(adapter.requests.single.path, '/api/student/email/confirm');
  });

  test('uploadDocument sends the name and the file as base64', () async {
    final adapter = _Adapter(201, {'status': 'pending', 'method': 'document'});
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final result = await _repo(
      adapter,
    ).uploadDocument(fullName: 'Kasun Perera', bytes: bytes);
    expect(
      (result as Ok<StudentApplication, AppFailure>).value.status,
      StudentStatus.pending,
    );
    final sent = adapter.requests.single;
    expect(sent.path, '/api/student/document');
    expect(sent.data, {
      'fullName': 'Kasun Perera',
      'data': base64Encode(bytes),
    });
    expect(sent.sendTimeout, const Duration(minutes: 2));
  });

  test(
    'a listed-domain refusal carries the backend code and message',
    () async {
      final result = await _repo(
        _Adapter(400, {
          'code': 'domain_not_listed',
          'message': 'Upload a student ID instead.',
        }),
      ).startEmail('a@gmail.com');
      final failure = (result as Err<void, AppFailure>).error;
      expect(failure, isA<StudentRequestFailure>());
      expect((failure as StudentRequestFailure).isDomainNotListed, isTrue);
      expect(failure.message, 'Upload a student ID instead.');
    },
  );

  test('413, 415, 409 and 429 keep the backend sentence', () async {
    for (final (status, message) in [
      (413, 'File too large, max 5 MB'),
      (415, 'Only JPG, PNG or PDF files are accepted'),
      (409, 'You already have a student year.'),
      (429, 'Too many wrong codes. Ask for a new code.'),
    ]) {
      final result = await _repo(
        _Adapter(status, {'message': message}),
      ).uploadDocument(fullName: 'Kasun', bytes: Uint8List(1));
      expect(
        (result as Err<StudentApplication, AppFailure>).error.message,
        message,
        reason: '$status',
      );
    }
  });

  test('needsNewCode is true for expired, locked and missing codes', () {
    for (final code in ['code_expired', 'too_many_attempts', 'no_code']) {
      expect(StudentRequestFailure(400, code, 'x').needsNewCode, isTrue);
    }
    expect(
      const StudentRequestFailure(400, 'wrong_code', 'x').needsNewCode,
      isFalse,
    );
  });

  test('other failures map exactly as everywhere else', () async {
    final result = await _repo(_Adapter(401, {'message': 'nope'})).status();
    expect(
      (result as Err<StudentApplication, AppFailure>).error,
      isA<AuthFailure>(),
    );
    final server = await _repo(_Adapter(500, {'message': 'x'})).status();
    expect(
      (server as Err<StudentApplication, AppFailure>).error,
      isA<ServerFailure>(),
    );
    // A 400 without a message is not a student explanation.
    final bare = await _repo(_Adapter(400, {})).status();
    expect(
      (bare as Err<StudentApplication, AppFailure>).error,
      isNot(isA<StudentRequestFailure>()),
    );
  });

  test('demo mode is read-only: no application, every write refused', () async {
    const demo = DemoStudentRepository();
    expect(
      ((await demo.status()) as Ok<StudentApplication, AppFailure>)
          .value
          .status,
      StudentStatus.none,
    );
    expect((await demo.startEmail('a@uom.ac.lk')).isErr, isTrue);
    expect((await demo.confirmEmail('123456')).isErr, isTrue);
    final upload = await demo.uploadDocument(
      fullName: 'Kasun',
      bytes: Uint8List(1),
    );
    expect(
      (upload as Err<StudentApplication, AppFailure>).error,
      isA<DemoUnavailableFailure>(),
    );
  });
}
