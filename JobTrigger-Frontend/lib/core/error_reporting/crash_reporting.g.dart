// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crash_reporting.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(crashReporting)
final crashReportingProvider = CrashReportingProvider._();

final class CrashReportingProvider
    extends $FunctionalProvider<CrashReporting, CrashReporting, CrashReporting>
    with $Provider<CrashReporting> {
  CrashReportingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'crashReportingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$crashReportingHash();

  @$internal
  @override
  $ProviderElement<CrashReporting> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CrashReporting create(Ref ref) {
    return crashReporting(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CrashReporting value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CrashReporting>(value),
    );
  }
}

String _$crashReportingHash() => r'f9c695d25d06382b7992dd8bee04a682f09c41d9';

/// The "Send crash reports" switch (PE-26): on by default, stored in
/// `shared_preferences`.

@ProviderFor(CrashReportsEnabled)
final crashReportsEnabledProvider = CrashReportsEnabledProvider._();

/// The "Send crash reports" switch (PE-26): on by default, stored in
/// `shared_preferences`.
final class CrashReportsEnabledProvider
    extends $NotifierProvider<CrashReportsEnabled, bool> {
  /// The "Send crash reports" switch (PE-26): on by default, stored in
  /// `shared_preferences`.
  CrashReportsEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'crashReportsEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$crashReportsEnabledHash();

  @$internal
  @override
  CrashReportsEnabled create() => CrashReportsEnabled();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$crashReportsEnabledHash() =>
    r'92bd52859d46a817058993426f71e74e7d4f749e';

/// The "Send crash reports" switch (PE-26): on by default, stored in
/// `shared_preferences`.

abstract class _$CrashReportsEnabled extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
