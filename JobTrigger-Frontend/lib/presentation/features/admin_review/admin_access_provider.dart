import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/admin_review_repository_impl.dart';
import '../../../domain/auth/auth_state.dart';
import '../auth/auth_notifier.dart';

part 'admin_access_provider.g.dart';

/// US-STU-02: whether the signed-in account may review student
/// applications (role `superAdmin`, asked of the backend, which checks it
/// again on every admin call). False when signed out, in demo mode, for
/// everyone else and on any failure, so the Profile row and the routes stay
/// hidden unless the server said yes. Not tied to billing.
@Riverpod(keepAlive: true)
Future<bool> adminAccess(Ref ref) async {
  final auth = ref.watch(authNotifierProvider).value;
  if (auth is! Authenticated) return false;
  final repository = ref.watch(adminReviewRepositoryProvider);
  return switch (await repository.hasAccess()) {
    Ok(:final value) => value,
    Err() => false,
  };
}
