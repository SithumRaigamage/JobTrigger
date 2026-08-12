// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credentials_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// List of saved Jenkins servers — see `docs/state-management.md`'s
/// "Feature: settings / server management" section. Follows the standard
/// shape from `docs/architecture.md §4`.

@ProviderFor(CredentialsNotifier)
final credentialsNotifierProvider = CredentialsNotifierProvider._();

/// List of saved Jenkins servers — see `docs/state-management.md`'s
/// "Feature: settings / server management" section. Follows the standard
/// shape from `docs/architecture.md §4`.
final class CredentialsNotifierProvider
    extends $AsyncNotifierProvider<CredentialsNotifier, List<JenkinsServer>> {
  /// List of saved Jenkins servers — see `docs/state-management.md`'s
  /// "Feature: settings / server management" section. Follows the standard
  /// shape from `docs/architecture.md §4`.
  CredentialsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'credentialsNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$credentialsNotifierHash();

  @$internal
  @override
  CredentialsNotifier create() => CredentialsNotifier();
}

String _$credentialsNotifierHash() =>
    r'8e35759bf2af67082f77d0c7899845acf6df1d3a';

/// List of saved Jenkins servers — see `docs/state-management.md`'s
/// "Feature: settings / server management" section. Follows the standard
/// shape from `docs/architecture.md §4`.

abstract class _$CredentialsNotifier
    extends $AsyncNotifier<List<JenkinsServer>> {
  FutureOr<List<JenkinsServer>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<JenkinsServer>>, List<JenkinsServer>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<JenkinsServer>>, List<JenkinsServer>>,
              AsyncValue<List<JenkinsServer>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
