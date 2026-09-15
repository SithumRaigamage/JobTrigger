import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'package_info_provider.g.dart';

/// The installed app's real version/build number — used for the profile
/// screen's version footer (P6-01). Cached for the process lifetime; the
/// installed version can't change without a fresh app launch.
@Riverpod(keepAlive: true)
Future<PackageInfo> packageInfo(Ref ref) => PackageInfo.fromPlatform();
