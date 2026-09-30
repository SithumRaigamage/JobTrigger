// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'console_notifiers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ConsolePrefsNotifier)
final consolePrefsNotifierProvider = ConsolePrefsNotifierProvider._();

final class ConsolePrefsNotifierProvider
    extends $NotifierProvider<ConsolePrefsNotifier, ConsolePrefs> {
  ConsolePrefsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'consolePrefsNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$consolePrefsNotifierHash();

  @$internal
  @override
  ConsolePrefsNotifier create() => ConsolePrefsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConsolePrefs value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConsolePrefs>(value),
    );
  }
}

String _$consolePrefsNotifierHash() =>
    r'5f56f32d6858c9870add33f093cad1983f22bcac';

abstract class _$ConsolePrefsNotifier extends $Notifier<ConsolePrefs> {
  ConsolePrefs build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ConsolePrefs, ConsolePrefs>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ConsolePrefs, ConsolePrefs>,
              ConsolePrefs,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Fetches timestamps for exactly the lines on screen (a negative
/// `startLine` counts back from the end, verified on the fixture), only
/// while the preference is on. While the log streams, it re-fetches at most
/// every [_throttle] rather than on every 1 s chunk.

@ProviderFor(ConsoleTimestampsNotifier)
final consoleTimestampsNotifierProvider = ConsoleTimestampsNotifierFamily._();

/// Fetches timestamps for exactly the lines on screen (a negative
/// `startLine` counts back from the end, verified on the fixture), only
/// while the preference is on. While the log streams, it re-fetches at most
/// every [_throttle] rather than on every 1 s chunk.
final class ConsoleTimestampsNotifierProvider
    extends
        $AsyncNotifierProvider<ConsoleTimestampsNotifier, ConsoleTimestamps> {
  /// Fetches timestamps for exactly the lines on screen (a negative
  /// `startLine` counts back from the end, verified on the fixture), only
  /// while the preference is on. While the log streams, it re-fetches at most
  /// every [_throttle] rather than on every 1 s chunk.
  ConsoleTimestampsNotifierProvider._({
    required ConsoleTimestampsNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'consoleTimestampsNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$consoleTimestampsNotifierHash();

  @override
  String toString() {
    return r'consoleTimestampsNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ConsoleTimestampsNotifier create() => ConsoleTimestampsNotifier();

  @override
  bool operator ==(Object other) {
    return other is ConsoleTimestampsNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$consoleTimestampsNotifierHash() =>
    r'15236a6fa6b6a5afab2316d3fd0c52ee9f1ad581';

/// Fetches timestamps for exactly the lines on screen (a negative
/// `startLine` counts back from the end, verified on the fixture), only
/// while the preference is on. While the log streams, it re-fetches at most
/// every [_throttle] rather than on every 1 s chunk.

final class ConsoleTimestampsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ConsoleTimestampsNotifier,
          AsyncValue<ConsoleTimestamps>,
          ConsoleTimestamps,
          FutureOr<ConsoleTimestamps>,
          String
        > {
  ConsoleTimestampsNotifierFamily._()
    : super(
        retry: null,
        name: r'consoleTimestampsNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches timestamps for exactly the lines on screen (a negative
  /// `startLine` counts back from the end, verified on the fixture), only
  /// while the preference is on. While the log streams, it re-fetches at most
  /// every [_throttle] rather than on every 1 s chunk.

  ConsoleTimestampsNotifierProvider call(String buildUrl) =>
      ConsoleTimestampsNotifierProvider._(argument: buildUrl, from: this);

  @override
  String toString() => r'consoleTimestampsNotifierProvider';
}

/// Fetches timestamps for exactly the lines on screen (a negative
/// `startLine` counts back from the end, verified on the fixture), only
/// while the preference is on. While the log streams, it re-fetches at most
/// every [_throttle] rather than on every 1 s chunk.

abstract class _$ConsoleTimestampsNotifier
    extends $AsyncNotifier<ConsoleTimestamps> {
  late final _$args = ref.$arg as String;
  String get buildUrl => _$args;

  FutureOr<ConsoleTimestamps> build(String buildUrl);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ConsoleTimestamps>, ConsoleTimestamps>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ConsoleTimestamps>, ConsoleTimestamps>,
              AsyncValue<ConsoleTimestamps>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(ConsoleSearchNotifier)
final consoleSearchNotifierProvider = ConsoleSearchNotifierFamily._();

final class ConsoleSearchNotifierProvider
    extends $NotifierProvider<ConsoleSearchNotifier, ConsoleSearch> {
  ConsoleSearchNotifierProvider._({
    required ConsoleSearchNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'consoleSearchNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$consoleSearchNotifierHash();

  @override
  String toString() {
    return r'consoleSearchNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ConsoleSearchNotifier create() => ConsoleSearchNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConsoleSearch value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConsoleSearch>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ConsoleSearchNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$consoleSearchNotifierHash() =>
    r'f408330ab6cdedec4e933dd9ab735f4ebc2aaf65';

final class ConsoleSearchNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ConsoleSearchNotifier,
          ConsoleSearch,
          ConsoleSearch,
          ConsoleSearch,
          String
        > {
  ConsoleSearchNotifierFamily._()
    : super(
        retry: null,
        name: r'consoleSearchNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ConsoleSearchNotifierProvider call(String buildUrl) =>
      ConsoleSearchNotifierProvider._(argument: buildUrl, from: this);

  @override
  String toString() => r'consoleSearchNotifierProvider';
}

abstract class _$ConsoleSearchNotifier extends $Notifier<ConsoleSearch> {
  late final _$args = ref.$arg as String;
  String get buildUrl => _$args;

  ConsoleSearch build(String buildUrl);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ConsoleSearch, ConsoleSearch>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ConsoleSearch, ConsoleSearch>,
              ConsoleSearch,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

/// US-JX-07 "Save full log": streams `consoleText` into a temp `.log` file,
/// shares it, then deletes it. The log can hold secrets Jenkins didn't
/// mask, so nothing is kept once it's been shared. State is loading while
/// the download runs.

@ProviderFor(FullLogExportNotifier)
final fullLogExportNotifierProvider = FullLogExportNotifierFamily._();

/// US-JX-07 "Save full log": streams `consoleText` into a temp `.log` file,
/// shares it, then deletes it. The log can hold secrets Jenkins didn't
/// mask, so nothing is kept once it's been shared. State is loading while
/// the download runs.
final class FullLogExportNotifierProvider
    extends $AsyncNotifierProvider<FullLogExportNotifier, void> {
  /// US-JX-07 "Save full log": streams `consoleText` into a temp `.log` file,
  /// shares it, then deletes it. The log can hold secrets Jenkins didn't
  /// mask, so nothing is kept once it's been shared. State is loading while
  /// the download runs.
  FullLogExportNotifierProvider._({
    required FullLogExportNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fullLogExportNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fullLogExportNotifierHash();

  @override
  String toString() {
    return r'fullLogExportNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  FullLogExportNotifier create() => FullLogExportNotifier();

  @override
  bool operator ==(Object other) {
    return other is FullLogExportNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fullLogExportNotifierHash() =>
    r'973d69215a94786fde52453999c9805c8eddaa04';

/// US-JX-07 "Save full log": streams `consoleText` into a temp `.log` file,
/// shares it, then deletes it. The log can hold secrets Jenkins didn't
/// mask, so nothing is kept once it's been shared. State is loading while
/// the download runs.

final class FullLogExportNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          FullLogExportNotifier,
          AsyncValue<void>,
          void,
          FutureOr<void>,
          String
        > {
  FullLogExportNotifierFamily._()
    : super(
        retry: null,
        name: r'fullLogExportNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// US-JX-07 "Save full log": streams `consoleText` into a temp `.log` file,
  /// shares it, then deletes it. The log can hold secrets Jenkins didn't
  /// mask, so nothing is kept once it's been shared. State is loading while
  /// the download runs.

  FullLogExportNotifierProvider call(String buildUrl) =>
      FullLogExportNotifierProvider._(argument: buildUrl, from: this);

  @override
  String toString() => r'fullLogExportNotifierProvider';
}

/// US-JX-07 "Save full log": streams `consoleText` into a temp `.log` file,
/// shares it, then deletes it. The log can hold secrets Jenkins didn't
/// mask, so nothing is kept once it's been shared. State is loading while
/// the download runs.

abstract class _$FullLogExportNotifier extends $AsyncNotifier<void> {
  late final _$args = ref.$arg as String;
  String get buildUrl => _$args;

  FutureOr<void> build(String buildUrl);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
