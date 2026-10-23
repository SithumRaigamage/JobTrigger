// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_credentials_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// List of saved SonarQube credentials — mirrors `GitHubCredentialsNotifier`'s
/// shape exactly, standard fetch-list notifier per
/// `docs/architecture.md §4`.

@ProviderFor(SonarQubeCredentialsNotifier)
final sonarQubeCredentialsNotifierProvider =
    SonarQubeCredentialsNotifierProvider._();

/// List of saved SonarQube credentials — mirrors `GitHubCredentialsNotifier`'s
/// shape exactly, standard fetch-list notifier per
/// `docs/architecture.md §4`.
final class SonarQubeCredentialsNotifierProvider
    extends
        $AsyncNotifierProvider<
          SonarQubeCredentialsNotifier,
          List<SonarQubeCredential>
        > {
  /// List of saved SonarQube credentials — mirrors `GitHubCredentialsNotifier`'s
  /// shape exactly, standard fetch-list notifier per
  /// `docs/architecture.md §4`.
  SonarQubeCredentialsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarQubeCredentialsNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeCredentialsNotifierHash();

  @$internal
  @override
  SonarQubeCredentialsNotifier create() => SonarQubeCredentialsNotifier();
}

String _$sonarQubeCredentialsNotifierHash() =>
    r'800b9b28a51b818bd9d8019d0474186634ff3808';

/// List of saved SonarQube credentials — mirrors `GitHubCredentialsNotifier`'s
/// shape exactly, standard fetch-list notifier per
/// `docs/architecture.md §4`.

abstract class _$SonarQubeCredentialsNotifier
    extends $AsyncNotifier<List<SonarQubeCredential>> {
  FutureOr<List<SonarQubeCredential>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<SonarQubeCredential>>,
              List<SonarQubeCredential>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<SonarQubeCredential>>,
                List<SonarQubeCredential>
              >,
              AsyncValue<List<SonarQubeCredential>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
