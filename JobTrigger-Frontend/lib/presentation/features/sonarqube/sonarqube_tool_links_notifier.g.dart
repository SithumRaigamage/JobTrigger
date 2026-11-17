// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_tool_links_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Which Jenkins jobs and GitHub repositories are linked to which SonarQube
/// project (`US-SQ-XTOOL-01..03`), for the active SonarQube credential.
///
/// **Device only**, in `shared_preferences`: project key and name against a
/// job URL or `owner/name`. No credential of any tool is stored or shared; the
/// card that uses a link calls SonarQube with the SonarQube credential only,
/// and the Jenkins and GitHub screens never see SonarQube's token.

@ProviderFor(SonarQubeToolLinksNotifier)
final sonarQubeToolLinksNotifierProvider =
    SonarQubeToolLinksNotifierProvider._();

/// Which Jenkins jobs and GitHub repositories are linked to which SonarQube
/// project (`US-SQ-XTOOL-01..03`), for the active SonarQube credential.
///
/// **Device only**, in `shared_preferences`: project key and name against a
/// job URL or `owner/name`. No credential of any tool is stored or shared; the
/// card that uses a link calls SonarQube with the SonarQube credential only,
/// and the Jenkins and GitHub screens never see SonarQube's token.
final class SonarQubeToolLinksNotifierProvider
    extends
        $NotifierProvider<
          SonarQubeToolLinksNotifier,
          Map<String, SonarQubeToolLink>
        > {
  /// Which Jenkins jobs and GitHub repositories are linked to which SonarQube
  /// project (`US-SQ-XTOOL-01..03`), for the active SonarQube credential.
  ///
  /// **Device only**, in `shared_preferences`: project key and name against a
  /// job URL or `owner/name`. No credential of any tool is stored or shared; the
  /// card that uses a link calls SonarQube with the SonarQube credential only,
  /// and the Jenkins and GitHub screens never see SonarQube's token.
  SonarQubeToolLinksNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarQubeToolLinksNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeToolLinksNotifierHash();

  @$internal
  @override
  SonarQubeToolLinksNotifier create() => SonarQubeToolLinksNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, SonarQubeToolLink> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, SonarQubeToolLink>>(
        value,
      ),
    );
  }
}

String _$sonarQubeToolLinksNotifierHash() =>
    r'1ecf39481302301b42f30cc18fa9dbd355a98971';

/// Which Jenkins jobs and GitHub repositories are linked to which SonarQube
/// project (`US-SQ-XTOOL-01..03`), for the active SonarQube credential.
///
/// **Device only**, in `shared_preferences`: project key and name against a
/// job URL or `owner/name`. No credential of any tool is stored or shared; the
/// card that uses a link calls SonarQube with the SonarQube credential only,
/// and the Jenkins and GitHub screens never see SonarQube's token.

abstract class _$SonarQubeToolLinksNotifier
    extends $Notifier<Map<String, SonarQubeToolLink>> {
  Map<String, SonarQubeToolLink> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              Map<String, SonarQubeToolLink>,
              Map<String, SonarQubeToolLink>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, SonarQubeToolLink>,
                Map<String, SonarQubeToolLink>
              >,
              Map<String, SonarQubeToolLink>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The Jenkins job URLs linked to [projectKey] (`US-SQ-XTOOL-02`): where
/// "Scan now" goes. Usually one, possibly none.

@ProviderFor(sonarQubeJenkinsJobsFor)
final sonarQubeJenkinsJobsForProvider = SonarQubeJenkinsJobsForFamily._();

/// The Jenkins job URLs linked to [projectKey] (`US-SQ-XTOOL-02`): where
/// "Scan now" goes. Usually one, possibly none.

final class SonarQubeJenkinsJobsForProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  /// The Jenkins job URLs linked to [projectKey] (`US-SQ-XTOOL-02`): where
  /// "Scan now" goes. Usually one, possibly none.
  SonarQubeJenkinsJobsForProvider._({
    required SonarQubeJenkinsJobsForFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sonarQubeJenkinsJobsForProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeJenkinsJobsForHash();

  @override
  String toString() {
    return r'sonarQubeJenkinsJobsForProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    final argument = this.argument as String;
    return sonarQubeJenkinsJobsFor(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SonarQubeJenkinsJobsForProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sonarQubeJenkinsJobsForHash() =>
    r'32922ecdcb9c1212e823031673b53b0fec70d3a0';

/// The Jenkins job URLs linked to [projectKey] (`US-SQ-XTOOL-02`): where
/// "Scan now" goes. Usually one, possibly none.

final class SonarQubeJenkinsJobsForFamily extends $Family
    with $FunctionalFamilyOverride<List<String>, String> {
  SonarQubeJenkinsJobsForFamily._()
    : super(
        retry: null,
        name: r'sonarQubeJenkinsJobsForProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The Jenkins job URLs linked to [projectKey] (`US-SQ-XTOOL-02`): where
  /// "Scan now" goes. Usually one, possibly none.

  SonarQubeJenkinsJobsForProvider call(String projectKey) =>
      SonarQubeJenkinsJobsForProvider._(argument: projectKey, from: this);

  @override
  String toString() => r'sonarQubeJenkinsJobsForProvider';
}
