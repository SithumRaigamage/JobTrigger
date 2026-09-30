// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_contents_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One folder's direct children, fetched on demand (P11-05) — [folderUrl]
/// is [rootFolderKey] for the server root. Home browses with this instead
/// of downloading the whole recursive tree up front (AUD-20), and a folder
/// is fetchable at any depth (AUD-19).
///
/// Cached for as long as it's on the current breadcrumb path —
/// `visibleJobsProvider` watches every ancestor — so walking back up
/// doesn't flash a spinner, and nothing lingers once Home is left.
/// Pull-to-refresh calls [refresh] for an immediate re-fetch. Rebuilt
/// automatically when the active server changes, via
/// `jenkinsRepositoryProvider`.

@ProviderFor(FolderContentsNotifier)
final folderContentsNotifierProvider = FolderContentsNotifierFamily._();

/// One folder's direct children, fetched on demand (P11-05) — [folderUrl]
/// is [rootFolderKey] for the server root. Home browses with this instead
/// of downloading the whole recursive tree up front (AUD-20), and a folder
/// is fetchable at any depth (AUD-19).
///
/// Cached for as long as it's on the current breadcrumb path —
/// `visibleJobsProvider` watches every ancestor — so walking back up
/// doesn't flash a spinner, and nothing lingers once Home is left.
/// Pull-to-refresh calls [refresh] for an immediate re-fetch. Rebuilt
/// automatically when the active server changes, via
/// `jenkinsRepositoryProvider`.
final class FolderContentsNotifierProvider
    extends $AsyncNotifierProvider<FolderContentsNotifier, List<JenkinsJob>> {
  /// One folder's direct children, fetched on demand (P11-05) — [folderUrl]
  /// is [rootFolderKey] for the server root. Home browses with this instead
  /// of downloading the whole recursive tree up front (AUD-20), and a folder
  /// is fetchable at any depth (AUD-19).
  ///
  /// Cached for as long as it's on the current breadcrumb path —
  /// `visibleJobsProvider` watches every ancestor — so walking back up
  /// doesn't flash a spinner, and nothing lingers once Home is left.
  /// Pull-to-refresh calls [refresh] for an immediate re-fetch. Rebuilt
  /// automatically when the active server changes, via
  /// `jenkinsRepositoryProvider`.
  FolderContentsNotifierProvider._({
    required FolderContentsNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'folderContentsNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$folderContentsNotifierHash();

  @override
  String toString() {
    return r'folderContentsNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  FolderContentsNotifier create() => FolderContentsNotifier();

  @override
  bool operator ==(Object other) {
    return other is FolderContentsNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$folderContentsNotifierHash() =>
    r'b47deb5006c9403a1dd08e47c5703d4a14bf9674';

/// One folder's direct children, fetched on demand (P11-05) — [folderUrl]
/// is [rootFolderKey] for the server root. Home browses with this instead
/// of downloading the whole recursive tree up front (AUD-20), and a folder
/// is fetchable at any depth (AUD-19).
///
/// Cached for as long as it's on the current breadcrumb path —
/// `visibleJobsProvider` watches every ancestor — so walking back up
/// doesn't flash a spinner, and nothing lingers once Home is left.
/// Pull-to-refresh calls [refresh] for an immediate re-fetch. Rebuilt
/// automatically when the active server changes, via
/// `jenkinsRepositoryProvider`.

final class FolderContentsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          FolderContentsNotifier,
          AsyncValue<List<JenkinsJob>>,
          List<JenkinsJob>,
          FutureOr<List<JenkinsJob>>,
          String
        > {
  FolderContentsNotifierFamily._()
    : super(
        retry: null,
        name: r'folderContentsNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One folder's direct children, fetched on demand (P11-05) — [folderUrl]
  /// is [rootFolderKey] for the server root. Home browses with this instead
  /// of downloading the whole recursive tree up front (AUD-20), and a folder
  /// is fetchable at any depth (AUD-19).
  ///
  /// Cached for as long as it's on the current breadcrumb path —
  /// `visibleJobsProvider` watches every ancestor — so walking back up
  /// doesn't flash a spinner, and nothing lingers once Home is left.
  /// Pull-to-refresh calls [refresh] for an immediate re-fetch. Rebuilt
  /// automatically when the active server changes, via
  /// `jenkinsRepositoryProvider`.

  FolderContentsNotifierProvider call(String folderUrl) =>
      FolderContentsNotifierProvider._(argument: folderUrl, from: this);

  @override
  String toString() => r'folderContentsNotifierProvider';
}

/// One folder's direct children, fetched on demand (P11-05) — [folderUrl]
/// is [rootFolderKey] for the server root. Home browses with this instead
/// of downloading the whole recursive tree up front (AUD-20), and a folder
/// is fetchable at any depth (AUD-19).
///
/// Cached for as long as it's on the current breadcrumb path —
/// `visibleJobsProvider` watches every ancestor — so walking back up
/// doesn't flash a spinner, and nothing lingers once Home is left.
/// Pull-to-refresh calls [refresh] for an immediate re-fetch. Rebuilt
/// automatically when the active server changes, via
/// `jenkinsRepositoryProvider`.

abstract class _$FolderContentsNotifier
    extends $AsyncNotifier<List<JenkinsJob>> {
  late final _$args = ref.$arg as String;
  String get folderUrl => _$args;

  FutureOr<List<JenkinsJob>> build(String folderUrl);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<JenkinsJob>>, List<JenkinsJob>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<JenkinsJob>>, List<JenkinsJob>>,
              AsyncValue<List<JenkinsJob>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
