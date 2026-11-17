// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'temp_files.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Where a file is written just long enough to share it (a full console
/// log, an artifact). A provider so tests can substitute it.

@ProviderFor(tempDirectory)
final tempDirectoryProvider = TempDirectoryProvider._();

/// Where a file is written just long enough to share it (a full console
/// log, an artifact). A provider so tests can substitute it.

final class TempDirectoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<Directory>,
          Directory,
          FutureOr<Directory>
        >
    with $FutureModifier<Directory>, $FutureProvider<Directory> {
  /// Where a file is written just long enough to share it (a full console
  /// log, an artifact). A provider so tests can substitute it.
  TempDirectoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tempDirectoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tempDirectoryHash();

  @$internal
  @override
  $FutureProviderElement<Directory> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Directory> create(Ref ref) {
    return tempDirectory(ref);
  }
}

String _$tempDirectoryHash() => r'718ce913427cdd69b83f62607a41dc4e52206d69';

/// A provider so tests can substitute it.

@ProviderFor(fileSharer)
final fileSharerProvider = FileSharerProvider._();

/// A provider so tests can substitute it.

final class FileSharerProvider
    extends $FunctionalProvider<FileSharer, FileSharer, FileSharer>
    with $Provider<FileSharer> {
  /// A provider so tests can substitute it.
  FileSharerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileSharerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileSharerHash();

  @$internal
  @override
  $ProviderElement<FileSharer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FileSharer create(Ref ref) {
    return fileSharer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FileSharer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FileSharer>(value),
    );
  }
}

String _$fileSharerHash() => r'fa0fac6c2e67a11bfdefde09fc247fe0649f8da2';
