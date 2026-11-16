// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locked_active_guard.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// P20-25: after a downgrade the backend marks credentials beyond the plan
/// as locked. If the *active* Jenkins server, GitHub credential or
/// SonarQube credential is one of them, this switches to the first unlocked
/// one (or to none), deletes the locked one's cached secret from secure
/// storage, and remembers the tool, so the next time the user opens it the
/// paywall opens with reason `locked` (see [consume]).
///
/// Billing on only: with billing off (or demo) the plan gate is inactive,
/// the credential lists are not even watched, and nothing here runs.
/// Watched from `main.dart`.

@ProviderFor(LockedActiveGuard)
final lockedActiveGuardProvider = LockedActiveGuardProvider._();

/// P20-25: after a downgrade the backend marks credentials beyond the plan
/// as locked. If the *active* Jenkins server, GitHub credential or
/// SonarQube credential is one of them, this switches to the first unlocked
/// one (or to none), deletes the locked one's cached secret from secure
/// storage, and remembers the tool, so the next time the user opens it the
/// paywall opens with reason `locked` (see [consume]).
///
/// Billing on only: with billing off (or demo) the plan gate is inactive,
/// the credential lists are not even watched, and nothing here runs.
/// Watched from `main.dart`.
final class LockedActiveGuardProvider
    extends $NotifierProvider<LockedActiveGuard, Set<CiTool>> {
  /// P20-25: after a downgrade the backend marks credentials beyond the plan
  /// as locked. If the *active* Jenkins server, GitHub credential or
  /// SonarQube credential is one of them, this switches to the first unlocked
  /// one (or to none), deletes the locked one's cached secret from secure
  /// storage, and remembers the tool, so the next time the user opens it the
  /// paywall opens with reason `locked` (see [consume]).
  ///
  /// Billing on only: with billing off (or demo) the plan gate is inactive,
  /// the credential lists are not even watched, and nothing here runs.
  /// Watched from `main.dart`.
  LockedActiveGuardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lockedActiveGuardProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lockedActiveGuardHash();

  @$internal
  @override
  LockedActiveGuard create() => LockedActiveGuard();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<CiTool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<CiTool>>(value),
    );
  }
}

String _$lockedActiveGuardHash() => r'66d331a42aa019c8655617d7e6087b5a834894f3';

/// P20-25: after a downgrade the backend marks credentials beyond the plan
/// as locked. If the *active* Jenkins server, GitHub credential or
/// SonarQube credential is one of them, this switches to the first unlocked
/// one (or to none), deletes the locked one's cached secret from secure
/// storage, and remembers the tool, so the next time the user opens it the
/// paywall opens with reason `locked` (see [consume]).
///
/// Billing on only: with billing off (or demo) the plan gate is inactive,
/// the credential lists are not even watched, and nothing here runs.
/// Watched from `main.dart`.

abstract class _$LockedActiveGuard extends $Notifier<Set<CiTool>> {
  Set<CiTool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<CiTool>, Set<CiTool>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<CiTool>, Set<CiTool>>,
              Set<CiTool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
