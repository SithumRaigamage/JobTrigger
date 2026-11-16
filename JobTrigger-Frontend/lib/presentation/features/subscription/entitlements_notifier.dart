import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/demo/demo_mode_notifier.dart';
import '../../../data/repositories/subscription_repository_impl.dart';
import '../../../domain/auth/auth_state.dart';
import '../../../domain/subscription/entitlements.dart';
import '../../../domain/subscription/subscription_status.dart';
import '../auth/auth_notifier.dart';
import 'billing_session.dart';

part 'entitlements_notifier.g.dart';

/// P20-22: what the signed-in user may do, and why (the plan, renewal date
/// and source). Loaded when the user signs in, again when the app returns
/// to the foreground, and after a purchase or restore ([apply]).
///
/// Never blocks and never fails the app: the first value is the cached one
/// (so gates are right offline), and an unreachable backend, an old
/// backend with no `/api/subscription`, demo mode and a signed-out session
/// all give [Entitlements.unrestricted], exactly as before subscriptions
/// existed. The backend enforces the real limits either way.
///
/// Created on first use: nothing reads it until a screen or gate does, so
/// a build that shows no subscription UI makes no extra request.
@Riverpod(keepAlive: true)
class EntitlementsNotifier extends _$EntitlementsNotifier {
  @override
  Future<SubscriptionSnapshot> build() async {
    ref.watch(billingSessionProvider);

    // E2: demo mode never reaches the backend.
    if (ref.watch(demoModeNotifierProvider)) return _unrestricted;
    // Rebuilds (and so reloads) on every sign-in and sign-out.
    // Waits for the startup session check rather than guessing.
    final auth = await ref.watch(authNotifierProvider.future);
    if (auth is! Authenticated) return _unrestricted;

    final observer = _ResumeObserver(() => unawaited(refresh()));
    WidgetsBinding.instance.addObserver(observer);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(observer));

    final repository = ref.read(subscriptionRepositoryProvider);
    final cached = await repository.cached();
    if (cached != null) {
      // Show the cached plan now and freshen it in the background.
      unawaited(Future.microtask(refresh));
      return cached;
    }
    return switch (await repository.load()) {
      Ok(:final value) => value,
      Err() => _unrestricted,
    };
  }

  /// Re-reads the plan from the backend. A failure keeps what is shown.
  Future<void> refresh() async {
    if (!ref.mounted) return;
    final result = await ref.read(subscriptionRepositoryProvider).load();
    if (!ref.mounted) return;
    if (result case Ok(:final value)) state = AsyncData(value);
  }

  /// Takes a fresh answer, e.g. from `POST /api/subscription/refresh` after
  /// a purchase or restore.
  void apply(SubscriptionSnapshot snapshot) => state = AsyncData(snapshot);
}

/// The entitlements alone, for gates. [Entitlements.unrestricted] until the
/// first answer arrives.
@Riverpod(keepAlive: true)
Entitlements entitlements(Ref ref) =>
    ref.watch(entitlementsNotifierProvider).value?.entitlements ??
    Entitlements.unrestricted;

const _unrestricted = SubscriptionSnapshot(
  entitlements: Entitlements.unrestricted,
  status: SubscriptionStatus.none,
);

class _ResumeObserver with WidgetsBindingObserver {
  _ResumeObserver(this.onResume);

  final void Function() onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}
