import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/guard.dart';
import '../../core/error/result.dart';
import '../../core/network/backend_api_client.dart';
import '../../domain/app_info/app_info.dart';
import '../../domain/app_info/app_info_repository.dart';
import '../models/app_info/app_info_dto.dart';

import '../demo/demo_account_repositories.dart';
import '../demo/demo_mode_notifier.dart';
part 'app_info_repository_impl.g.dart';

class AppInfoRepositoryImpl implements AppInfoRepository {
  AppInfoRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<AppInfo, AppFailure>> fetchAppInfo() => guardRequest(() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/appinfo');
    return AppInfoDto.fromJson(response.data!).toDomain();
  });
}

@riverpod
AppInfoRepository appInfoRepository(Ref ref) {
  // E2: demo mode never reaches the backend.
  if (ref.watch(demoModeNotifierProvider)) return demoAppInfoRepository;
  return AppInfoRepositoryImpl(ref.watch(dioBackendProvider));
}
