import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/support_repository_impl.dart';
import '../../../domain/support/support_category.dart';
import '../../../domain/support/support_diagnostics.dart';
import '../../../domain/support/support_ticket.dart';
import 'my_support_tickets_notifier.dart';

part 'support_form_notifier.g.dart';

/// P25-05: one in-flight submission. `null` means nothing sent yet; a value
/// is the ticket the backend stored; an error is what to show under the form.
@riverpod
class SupportFormNotifier extends _$SupportFormNotifier {
  @override
  FutureOr<SupportTicket?> build() => null;

  Future<SupportTicket?> submit({
    required SupportCategory category,
    required String subject,
    required String message,
    String? replyEmail,
    SupportDiagnostics? diagnostics,
  }) async {
    state = const AsyncValue.loading();
    final result = await ref
        .read(supportRepositoryProvider)
        .submit(
          category: category,
          subject: subject,
          message: message,
          replyEmail: replyEmail,
          diagnostics: diagnostics,
        );
    switch (result) {
      case Ok(:final value):
        state = AsyncValue.data(value);
        ref.invalidate(mySupportTicketsNotifierProvider);
        return value;
      case Err(:final error):
        state = AsyncValue.error(error, StackTrace.current);
        return null;
    }
  }

  /// "Send another" clears the sent ticket; a kept error would hide the form
  /// state the user is about to replace.
  void reset() => state = const AsyncValue.data(null);
}
