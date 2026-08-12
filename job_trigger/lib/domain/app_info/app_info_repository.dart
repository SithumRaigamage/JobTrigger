import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import 'app_info.dart';

abstract class AppInfoRepository {
  Future<Result<AppInfo, AppFailure>> fetchAppInfo();
}
