import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/guard.dart';
import '../../core/error/result.dart';
import '../../core/network/backend_api_client.dart';
import '../../domain/student/student_application.dart';
import '../../domain/student/student_repository.dart';
import '../demo/demo_mode_notifier.dart';
import '../demo/demo_student_repository.dart';
import '../models/student/student_dto.dart';

part 'student_repository_impl.g.dart';

/// A 5 MB file is about 7 MB of base64 on a phone connection.
const _uploadTimeout = Duration(minutes: 2);

class StudentRepositoryImpl implements StudentRepository {
  StudentRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<StudentApplication, AppFailure>> status() => guardRequest(
    () async => StudentApplicationDto.fromJson(
      (await _dio.get<Map<String, dynamic>>('/api/student')).data!,
    ).toDomain(),
    mapDioException: AppFailure.fromStudentException,
  );

  @override
  Future<Result<void, AppFailure>> startEmail(String universityEmail) =>
      guardRequest<void>(
        () => _dio.post<Map<String, dynamic>>(
          '/api/student/email/start',
          data: {'universityEmail': universityEmail},
        ),
        mapDioException: AppFailure.fromStudentException,
      );

  @override
  Future<Result<StudentApplication, AppFailure>> confirmEmail(String code) =>
      guardRequest(
        () async => StudentApplicationDto.fromJson(
          (await _dio.post<Map<String, dynamic>>(
            '/api/student/email/confirm',
            data: {'code': code},
          )).data!,
        ).toDomain(),
        mapDioException: AppFailure.fromStudentException,
      );

  @override
  Future<Result<StudentApplication, AppFailure>> uploadDocument({
    required String fullName,
    required Uint8List bytes,
  }) => guardRequest(
    () async => StudentApplicationDto.fromJson(
      (await _dio.post<Map<String, dynamic>>(
        '/api/student/document',
        data: {'fullName': fullName, 'data': base64Encode(bytes)},
        options: Options(
          sendTimeout: _uploadTimeout,
          receiveTimeout: _uploadTimeout,
        ),
      )).data!,
    ).toDomain(),
    mapDioException: AppFailure.fromStudentException,
  );
}

@riverpod
StudentRepository studentRepository(Ref ref) {
  // E2: demo mode never reaches the backend.
  if (ref.watch(demoModeNotifierProvider)) return demoStudentRepository;
  return StudentRepositoryImpl(ref.watch(dioBackendProvider));
}
