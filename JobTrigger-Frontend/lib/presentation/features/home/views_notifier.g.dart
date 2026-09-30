// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'views_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-JX-17: the active server's views. Additive: if they can't be loaded,
/// Home simply shows no picker.

@ProviderFor(jenkinsViews)
final jenkinsViewsProvider = JenkinsViewsProvider._();

/// US-JX-17: the active server's views. Additive: if they can't be loaded,
/// Home simply shows no picker.

final class JenkinsViewsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<JenkinsView>>,
          List<JenkinsView>,
          FutureOr<List<JenkinsView>>
        >
    with
        $FutureModifier<List<JenkinsView>>,
        $FutureProvider<List<JenkinsView>> {
  /// US-JX-17: the active server's views. Additive: if they can't be loaded,
  /// Home simply shows no picker.
  JenkinsViewsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'jenkinsViewsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$jenkinsViewsHash();

  @$internal
  @override
  $FutureProviderElement<List<JenkinsView>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<JenkinsView>> create(Ref ref) {
    return jenkinsViews(ref);
  }
}

String _$jenkinsViewsHash() => r'e0f88f98a44bf4180b2367385f75a2d6eab60267';

/// US-JX-17: the view Home lists, as its URL; null means the primary view
/// (the plain root). Persisted per server, like pins.

@ProviderFor(SelectedViewNotifier)
final selectedViewNotifierProvider = SelectedViewNotifierProvider._();

/// US-JX-17: the view Home lists, as its URL; null means the primary view
/// (the plain root). Persisted per server, like pins.
final class SelectedViewNotifierProvider
    extends $NotifierProvider<SelectedViewNotifier, String?> {
  /// US-JX-17: the view Home lists, as its URL; null means the primary view
  /// (the plain root). Persisted per server, like pins.
  SelectedViewNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedViewNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedViewNotifierHash();

  @$internal
  @override
  SelectedViewNotifier create() => SelectedViewNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$selectedViewNotifierHash() =>
    r'cb076972a7872d9b931c90fef7f8599d34e4d46b';

/// US-JX-17: the view Home lists, as its URL; null means the primary view
/// (the plain root). Persisted per server, like pins.

abstract class _$SelectedViewNotifier extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
