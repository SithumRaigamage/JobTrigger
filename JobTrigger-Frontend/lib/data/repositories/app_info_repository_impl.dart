import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import '../../core/network/backend_api_client.dart';
import '../../domain/app_info/app_info.dart';
import '../../domain/app_info/app_info_repository.dart';
import '../models/app_info/app_info_dto.dart';

part 'app_info_repository_impl.g.dart';

class AppInfoRepositoryImpl implements AppInfoRepository {
  AppInfoRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<AppInfo, AppFailure>> fetchAppInfo() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/appinfo');
      return Ok(AppInfoDto.fromJson(response.data!).toDomain());
    } on DioException catch (exception) {
      return Err(AppFailure.fromDioException(exception));
    }
  }
}

@riverpod
AppInfoRepository appInfoRepository(Ref ref) =>
    AppInfoRepositoryImpl(ref.watch(dioBackendProvider));
