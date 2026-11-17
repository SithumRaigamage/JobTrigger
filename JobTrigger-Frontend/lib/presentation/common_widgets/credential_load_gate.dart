import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/error_message.dart';
import 'connection_error_view.dart';

/// What a tool's Home shows while it has no *active* credential yet.
///
/// The active credential is `null` both while the saved list is still being
/// fetched from the backend and when there is none, so a screen that only
/// checks for `null` flashes "no credential" at someone who has one. This is
/// the same fix Jenkins got (P19-02), as one widget for the other tools:
///
///  * the list is loading, or loaded but the active one isn't picked yet:
///    a spinner;
///  * the list failed to load: the error with a retry;
///  * the list loaded and is empty: [none].
class CredentialLoadGate extends StatelessWidget {
  const CredentialLoadGate({
    super.key,
    required this.saved,
    required this.none,
    required this.onRetry,
  });

  /// The tool's saved-credentials list.
  final AsyncValue<List<Object?>> saved;

  /// Shown when there really is no saved credential.
  final Widget none;

  /// Reloads the list and re-picks the active credential.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // Checked first: while Riverpod retries a failed load the value reads as
    // loading yet still carries the error, which the user should see now.
    if (saved.hasError) {
      return ConnectionErrorView(
        message: describeError(saved.error!),
        onRetry: onRetry,
      );
    }
    return switch (saved) {
      AsyncData(:final value) when value.isEmpty => none,
      _ => const CircularProgressIndicator(),
    };
  }
}
