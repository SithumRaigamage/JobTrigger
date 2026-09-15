import 'app_failure.dart';

/// Renders any error surfaced via `AsyncError` to user-facing text — covers
/// both `AppFailure` (repository/network outcomes) and client-side form
/// validation errors (e.g. `FormValidationError`) that never reach the
/// network, without notifiers/screens needing to know which is which.
String describeError(Object error) => switch (error) {
  AppFailure() => error.message,
  _ => error.toString(),
};
