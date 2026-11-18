import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/support_repository_impl.dart';
import '../../../domain/support/support_ticket.dart';

part 'my_support_tickets_notifier.g.dart';

/// P25-05: the caller's own reports (`GET /api/support/tickets`), newest
/// first, so the Support screen can show whether an earlier report was seen.
@riverpod
class MySupportTicketsNotifier extends _$MySupportTicketsNotifier {
  @override
  Future<List<SupportTicket>> build() async {
    final result = await ref.watch(supportRepositoryProvider).fetchMine();
    return switch (result) {
      Ok(:final value) => value,
      Err(:final error) => throw error,
    };
  }

  Future<void> refresh() async => ref.invalidateSelf();
}
