// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_breadcrumb_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Navigation stack for folder drill-down — pure local UI state, no
/// repository calls (`docs/state-management.md`). `navigateInto`/
/// `navigateBack` port `HomeViewModel.navigateInto`/`navigateBack` (Swift).

@ProviderFor(FolderBreadcrumbNotifier)
final folderBreadcrumbNotifierProvider = FolderBreadcrumbNotifierProvider._();

/// Navigation stack for folder drill-down — pure local UI state, no
/// repository calls (`docs/state-management.md`). `navigateInto`/
/// `navigateBack` port `HomeViewModel.navigateInto`/`navigateBack` (Swift).
final class FolderBreadcrumbNotifierProvider
    extends $NotifierProvider<FolderBreadcrumbNotifier, List<JenkinsJob>> {
  /// Navigation stack for folder drill-down — pure local UI state, no
  /// repository calls (`docs/state-management.md`). `navigateInto`/
  /// `navigateBack` port `HomeViewModel.navigateInto`/`navigateBack` (Swift).
  FolderBreadcrumbNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'folderBreadcrumbNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$folderBreadcrumbNotifierHash();

  @$internal
  @override
  FolderBreadcrumbNotifier create() => FolderBreadcrumbNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<JenkinsJob> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<JenkinsJob>>(value),
    );
  }
}

String _$folderBreadcrumbNotifierHash() =>
    r'66e3e34e127a4aa804c3ccd9ef663aae390159c6';

/// Navigation stack for folder drill-down — pure local UI state, no
/// repository calls (`docs/state-management.md`). `navigateInto`/
/// `navigateBack` port `HomeViewModel.navigateInto`/`navigateBack` (Swift).

abstract class _$FolderBreadcrumbNotifier extends $Notifier<List<JenkinsJob>> {
  List<JenkinsJob> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<JenkinsJob>, List<JenkinsJob>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<JenkinsJob>, List<JenkinsJob>>,
              List<JenkinsJob>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
