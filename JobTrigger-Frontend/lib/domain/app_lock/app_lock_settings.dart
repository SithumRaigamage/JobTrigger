/// US-JX-21: the user's app-lock choices. Not secret: they gate the UI only,
/// and every credential stays in secure storage either way.
class AppLockSettings {
  const AppLockSettings({
    this.enabled = false,
    this.timeout = const Duration(minutes: 5),
    this.requireForSensitive = false,
  });

  /// The resume timeouts offered in Settings.
  static const timeouts = [
    Duration.zero,
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
  ];

  final bool enabled;

  /// How long the app may sit in the background before it locks again.
  final Duration timeout;

  /// Re-prompt before trigger, cancel, input approval, replay, node toggle,
  /// and job disable. Only meaningful while [enabled].
  final bool requireForSensitive;

  AppLockSettings copyWith({
    bool? enabled,
    Duration? timeout,
    bool? requireForSensitive,
  }) => AppLockSettings(
    enabled: enabled ?? this.enabled,
    timeout: timeout ?? this.timeout,
    requireForSensitive: requireForSensitive ?? this.requireForSensitive,
  );
}

/// Whether coming back to the foreground should lock the app.
///
/// [backgroundedAt] is when the app last left the foreground, or null if it
/// hasn't since the last unlock.
bool shouldLockOnResume({
  required AppLockSettings settings,
  required DateTime? backgroundedAt,
  required DateTime now,
}) {
  if (!settings.enabled || backgroundedAt == null) return false;
  return now.difference(backgroundedAt) >= settings.timeout;
}
