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
///
/// Watches the active server, so switching servers rebuilds this back to
/// the root — previously the breadcrumb (and the folder contents it held)
/// survived a switch, showing server A's folder under server B (AUD-10).

@ProviderFor(FolderBreadcrumbNotifier)
final folderBreadcrumbNotifierProvider = FolderBreadcrumbNotifierProvider._();

/// Navigation stack for folder drill-down — pure local UI state, no
/// repository calls (`docs/state-management.md`). `navigateInto`/
/// `navigateBack` port `HomeViewModel.navigateInto`/`navigateBack` (Swift).
///
/// Watches the active server, so switching servers rebuilds this back to
/// the root — previously the breadcrumb (and the folder contents it held)
/// survived a switch, showing server A's folder under server B (AUD-10).
final class FolderBreadcrumbNotifierProvider
    extends $NotifierProvider<FolderBreadcrumbNotifier, List<FolderRef>> {
  /// Navigation stack for folder drill-down — pure local UI state, no
  /// repository calls (`docs/state-management.md`). `navigateInto`/
  /// `navigateBack` port `HomeViewModel.navigateInto`/`navigateBack` (Swift).
  ///
  /// Watches the active server, so switching servers rebuilds this back to
  /// the root — previously the breadcrumb (and the folder contents it held)
  /// survived a switch, showing server A's folder under server B (AUD-10).
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
  Override overrideWithValue(List<FolderRef> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FolderRef>>(value),
    );
  }
}

String _$folderBreadcrumbNotifierHash() =>
    r'9cafbbb9e6f4df528e544e0605866bc754b6c93c';

/// Navigation stack for folder drill-down — pure local UI state, no
/// repository calls (`docs/state-management.md`). `navigateInto`/
/// `navigateBack` port `HomeViewModel.navigateInto`/`navigateBack` (Swift).
///
/// Watches the active server, so switching servers rebuilds this back to
/// the root — previously the breadcrumb (and the folder contents it held)
/// survived a switch, showing server A's folder under server B (AUD-10).

abstract class _$FolderBreadcrumbNotifier extends $Notifier<List<FolderRef>> {
  List<FolderRef> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<FolderRef>, List<FolderRef>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<FolderRef>, List<FolderRef>>,
              List<FolderRef>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
