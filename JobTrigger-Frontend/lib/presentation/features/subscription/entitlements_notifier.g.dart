// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entitlements_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(EntitlementsNotifier)
final entitlementsNotifierProvider = EntitlementsNotifierProvider._();

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
final class EntitlementsNotifierProvider
    extends $AsyncNotifierProvider<EntitlementsNotifier, SubscriptionSnapshot> {
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
  EntitlementsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'entitlementsNotifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$entitlementsNotifierHash();

  @$internal
  @override
  EntitlementsNotifier create() => EntitlementsNotifier();
}

String _$entitlementsNotifierHash() =>
    r'e4f80cc207029f3baf74e22ea17a72f9eee1e97b';

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

abstract class _$EntitlementsNotifier
    extends $AsyncNotifier<SubscriptionSnapshot> {
  FutureOr<SubscriptionSnapshot> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<SubscriptionSnapshot>, SubscriptionSnapshot>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<SubscriptionSnapshot>,
                SubscriptionSnapshot
              >,
              AsyncValue<SubscriptionSnapshot>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The entitlements alone, for gates. [Entitlements.unrestricted] until the
/// first answer arrives.

@ProviderFor(entitlements)
final entitlementsProvider = EntitlementsProvider._();

/// The entitlements alone, for gates. [Entitlements.unrestricted] until the
/// first answer arrives.

final class EntitlementsProvider
    extends $FunctionalProvider<Entitlements, Entitlements, Entitlements>
    with $Provider<Entitlements> {
  /// The entitlements alone, for gates. [Entitlements.unrestricted] until the
  /// first answer arrives.
  EntitlementsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'entitlementsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$entitlementsHash();

  @$internal
  @override
  $ProviderElement<Entitlements> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Entitlements create(Ref ref) {
    return entitlements(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Entitlements value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Entitlements>(value),
    );
  }
}

String _$entitlementsHash() => r'46431c2b4a358949bb8e81a17ed5fd2c7c0b3fe1';
