import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/server_status.dart';

part 'server_status_provider.g.dart';

/// US-JX-18: the active server's version and quiet-down state. Additive:
/// a failure yields an empty status rather than an error, so it never
/// blocks Home or Settings. Rebuilt when the active server changes.
@riverpod
Future<ServerStatus> serverStatus(Ref ref) async {
  final result = await ref.watch(jenkinsRepositoryProvider).fetchServerStatus();
  return switch (result) {
    Ok(:final value) => value,
    Err() => const ServerStatus(),
  };
}
