import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/guard.dart';
import '../../core/error/result.dart';
import '../../core/network/backend_api_client.dart';
import '../../domain/admin_review/admin_review_repository.dart';
import '../../domain/admin_review/admin_student_application.dart';
import '../demo/demo_admin_review_repository.dart';
import '../demo/demo_mode_notifier.dart';
import '../models/admin_review/admin_student_dto.dart';

part 'admin_review_repository_impl.g.dart';

/// A 5 MB file on a phone connection.
const _documentTimeout = Duration(minutes: 2);
const _base = '/api/admin/students';

class AdminReviewRepositoryImpl implements AdminReviewRepository {
  AdminReviewRepositoryImpl(this._dio);

  final Dio _dio;

  static AdminStudentApplication _item(Map<String, dynamic>? body) =>
      AdminStudentDto.fromJson(body!).toDomain();

  @override
  Future<Result<bool, AppFailure>> hasAccess() => guardRequest(
    () async {
      final body = (await _dio.get<Map<String, dynamic>>('$_base/access')).data;
      return body?['role'] == 'superAdmin';
    },
    // Everyone who isn't a super admin gets the backend's plain 404.
    recover: (e) => e.response?.statusCode == 404 ? const Ok(false) : null,
  );

  @override
  Future<Result<List<AdminStudentApplication>, AppFailure>> list(
    AdminStatusFilter filter,
  ) => guardRequest(() async {
    final body = (await _dio.get<Map<String, dynamic>>(
      _base,
      queryParameters: {'status': filter.query},
    )).data!;
    return [
      for (final item in body['items'] as List<dynamic>)
        AdminStudentDto.fromJson(item as Map<String, dynamic>).toDomain(),
    ];
  }, mapDioException: AppFailure.fromStudentException);

  @override
  Future<Result<AdminStudentApplication, AppFailure>> get(String id) =>
      guardRequest(
        () async => _item(
          (await _dio.get<Map<String, dynamic>>(
            '$_base/${Uri.encodeComponent(id)}',
          )).data,
        ),
        mapDioException: AppFailure.fromStudentException,
      );

  @override
  Future<Result<AdminStudentDocument?, AppFailure>> document(String id) =>
      guardRequest<AdminStudentDocument?>(
        () async {
          // Bytes straight into memory: Dio keeps no cache, and nothing here
          // writes a file (US-STU-02).
          final response = await _dio.get<List<int>>(
            '$_base/${Uri.encodeComponent(id)}/document',
            options: Options(
              responseType: ResponseType.bytes,
              receiveTimeout: _documentTimeout,
            ),
          );
          final mime =
              response.headers
                  .value(Headers.contentTypeHeader)
                  ?.split(';')
                  .first
                  .trim() ??
              'application/octet-stream';
          return AdminStudentDocument(
            mime: mime,
            bytes: Uint8List.fromList(response.data ?? const []),
          );
        },
        recover: (e) => e.response?.statusCode == 410 ? const Ok(null) : null,
        mapDioException: AppFailure.fromStudentException,
      );

  @override
  Future<Result<AdminStudentApplication, AppFailure>> approve(String id) =>
      guardRequest(
        () async => _item(
          (await _dio.post<Map<String, dynamic>>(
            '$_base/${Uri.encodeComponent(id)}/approve',
          )).data,
        ),
        mapDioException: AppFailure.fromStudentException,
      );

  @override
  Future<Result<AdminStudentApplication, AppFailure>> reject(
    String id,
    String reason,
  ) => guardRequest(
    () async => _item(
      (await _dio.post<Map<String, dynamic>>(
        '$_base/${Uri.encodeComponent(id)}/reject',
        data: {'reason': reason},
      )).data,
    ),
    mapDioException: AppFailure.fromStudentException,
  );
}

@riverpod
AdminReviewRepository adminReviewRepository(Ref ref) {
  // E2: demo mode never reaches the backend and is never an admin.
  if (ref.watch(demoModeNotifierProvider)) return demoAdminReviewRepository;
  return AdminReviewRepositoryImpl(ref.watch(dioBackendProvider));
}
