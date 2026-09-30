import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/platform/biometric_service.dart';
import '../../../domain/app_lock/app_lock_settings.dart';

part 'app_lock_notifier.g.dart';

const _enabledKey = 'app_lock_enabled';
const _timeoutKey = 'app_lock_timeout_seconds';
const _sensitiveKey = 'app_lock_sensitive';

/// What the lock gate shows.
class AppLockState {
  const AppLockState({
    this.settings = const AppLockSettings(),
    this.loaded = false,
    this.locked = false,
    this.obscured = false,
  });

  final AppLockSettings settings;

  /// False until the settings are read, so a locked app never flashes its
  /// content on a cold start.
  final bool loaded;
  final bool locked;

  /// The app is inactive or backgrounded: hide the content from the app
  /// switcher snapshot.
  final bool obscured;

  AppLockState copyWith({
    AppLockSettings? settings,
    bool? loaded,
    bool? locked,
    bool? obscured,
  }) => AppLockState(
    settings: settings ?? this.settings,
    loaded: loaded ?? this.loaded,
    locked: locked ?? this.locked,
    obscured: obscured ?? this.obscured,
  );
}

/// Why turning the lock on didn't happen.
enum LockChange { changed, cancelled, noDeviceSecurity }

/// US-JX-21: the biometric app lock. Locks on a cold start and on resume
/// after [AppLockSettings.timeout] in the background; optionally re-prompts
/// before sensitive actions. It gates the UI only: secrets stay in secure
/// storage either way.
@Riverpod(keepAlive: true)
class AppLockNotifier extends _$AppLockNotifier {
  DateTime? _backgroundedAt;

  /// The OS prompt itself makes the app inactive (and on some devices
  /// paused); those transitions must not lock it again.
  bool _authenticating = false;

  /// Injectable clock for tests.
  @visibleForTesting
  DateTime Function() now = DateTime.now;

  @override
  AppLockState build() {
    _load();
    return const AppLockState();
  }

  Future<void> _load() async {
    var settings = const AppLockSettings();
    try {
      final prefs = await SharedPreferences.getInstance();
      settings = AppLockSettings(
        enabled: prefs.getBool(_enabledKey) ?? false,
        timeout: _offeredTimeout(prefs.getInt(_timeoutKey)),
        requireForSensitive: prefs.getBool(_sensitiveKey) ?? false,
      );
    } on Object {
      // Unreadable prefs: fall back to the defaults (lock off).
    }
    if (!ref.mounted) return;
    state = state.copyWith(
      settings: settings,
      loaded: true,
      locked: settings.enabled,
    );
    if (settings.enabled) unawaited(unlock()); // Prompt straight away.
  }

  /// Anything but an offered value (say, a stale or corrupt pref) falls
  /// back to the default, so Settings can always show it.
  static Duration _offeredTimeout(int? seconds) {
    final timeout = Duration(seconds: seconds ?? -1);
    return AppLockSettings.timeouts.contains(timeout)
        ? timeout
        : const AppLockSettings().timeout;
  }

  /// Fed by the gate's lifecycle listener.
  void onLifecycleChanged(AppLifecycleState lifecycle) {
    if (_authenticating) return;
    switch (lifecycle) {
      case AppLifecycleState.resumed:
        final lock = shouldLockOnResume(
          settings: state.settings,
          backgroundedAt: _backgroundedAt,
          now: now(),
        );
        _backgroundedAt = null;
        final newlyLocked = lock && !state.locked;
        state = state.copyWith(obscured: false, locked: state.locked || lock);
        if (newlyLocked) unawaited(unlock());
      case AppLifecycleState.inactive:
        state = state.copyWith(obscured: state.settings.enabled);
      case AppLifecycleState.hidden ||
          AppLifecycleState.paused ||
          AppLifecycleState.detached:
        _backgroundedAt ??= now();
        state = state.copyWith(obscured: state.settings.enabled);
    }
  }

  /// Asks the OS to authenticate and unlocks on success.
  Future<void> unlock() async {
    if (!state.locked || _authenticating) return;
    final outcome = await _authenticate('Unlock JobTrigger');
    switch (outcome) {
      case AuthOutcome.success:
        state = state.copyWith(locked: false);
      case AuthOutcome.unavailable:
        // The device's passcode was removed after the lock was enabled:
        // nothing can satisfy it any more, so turn it off rather than lock
        // the user out for good.
        await _save(state.settings.copyWith(enabled: false));
        state = state.copyWith(locked: false);
      case AuthOutcome.failed:
        break;
    }
  }

  /// Gate for sensitive actions. True when allowed to proceed.
  Future<bool> confirmSensitive(String reason) async {
    final settings = state.settings;
    if (!settings.enabled || !settings.requireForSensitive) return true;
    return await _authenticate(reason) == AuthOutcome.success;
  }

  /// Turning the lock on authenticates once first, which also proves the
  /// device has a passcode or biometrics set up.
  Future<LockChange> setEnabled(bool enabled) async {
    if (enabled) {
      final outcome = await _authenticate('Turn on app lock');
      if (outcome == AuthOutcome.unavailable) {
        return LockChange.noDeviceSecurity;
      }
      if (outcome != AuthOutcome.success) return LockChange.cancelled;
    }
    await _save(state.settings.copyWith(enabled: enabled));
    return LockChange.changed;
  }

  Future<void> setTimeout(Duration timeout) =>
      _save(state.settings.copyWith(timeout: timeout));

  Future<void> setRequireForSensitive(bool value) =>
      _save(state.settings.copyWith(requireForSensitive: value));

  Future<AuthOutcome> _authenticate(String reason) async {
    _authenticating = true;
    try {
      return await ref.read(biometricServiceProvider).authenticate(reason);
    } finally {
      _authenticating = false;
      // Prompt-induced lifecycle changes were ignored; start clean.
      _backgroundedAt = null;
      if (ref.mounted) state = state.copyWith(obscured: false);
    }
  }

  Future<void> _save(AppLockSettings settings) async {
    state = state.copyWith(settings: settings);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, settings.enabled);
    await prefs.setInt(_timeoutKey, settings.timeout.inSeconds);
    await prefs.setBool(_sensitiveKey, settings.requireForSensitive);
  }
}
