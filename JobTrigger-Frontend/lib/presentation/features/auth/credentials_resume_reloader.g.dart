// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credentials_resume_reloader.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-WEB-17 (owner decision 2026-11-21): when the app comes back to the
/// foreground, reload every tool's saved credentials, so a server added on
/// the website appears without a restart; at most once every [minGap]. The
/// reload also retries a default still waiting to reach the backend and
/// picks up one chosen elsewhere (US-CRED-05, US-WEB-18). Watched by the
/// app root.

@ProviderFor(CredentialsResumeReloader)
final credentialsResumeReloaderProvider = CredentialsResumeReloaderProvider._();

/// US-WEB-17 (owner decision 2026-11-21): when the app comes back to the
/// foreground, reload every tool's saved credentials, so a server added on
/// the website appears without a restart; at most once every [minGap]. The
/// reload also retries a default still waiting to reach the backend and
/// picks up one chosen elsewhere (US-CRED-05, US-WEB-18). Watched by the
/// app root.
final class CredentialsResumeReloaderProvider
    extends $NotifierProvider<CredentialsResumeReloader, void> {
  /// US-WEB-17 (owner decision 2026-11-21): when the app comes back to the
  /// foreground, reload every tool's saved credentials, so a server added on
  /// the website appears without a restart; at most once every [minGap]. The
  /// reload also retries a default still waiting to reach the backend and
  /// picks up one chosen elsewhere (US-CRED-05, US-WEB-18). Watched by the
  /// app root.
  CredentialsResumeReloaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'credentialsResumeReloaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$credentialsResumeReloaderHash();

  @$internal
  @override
  CredentialsResumeReloader create() => CredentialsResumeReloader();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$credentialsResumeReloaderHash() =>
    r'be8e0ec00e86ffe41bf3d201d3c2d72cfc9266eb';

/// US-WEB-17 (owner decision 2026-11-21): when the app comes back to the
/// foreground, reload every tool's saved credentials, so a server added on
/// the website appears without a restart; at most once every [minGap]. The
/// reload also retries a default still waiting to reach the backend and
/// picks up one chosen elsewhere (US-CRED-05, US-WEB-18). Watched by the
/// app root.

abstract class _$CredentialsResumeReloader extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
