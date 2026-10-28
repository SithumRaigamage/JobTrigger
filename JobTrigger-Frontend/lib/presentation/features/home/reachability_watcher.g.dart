// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reachability_watcher.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-JX-20: notices a Jenkins outage (or its return) while Home is already
/// on screen — on a timer, and when the app comes back to the foreground.
/// Watched by `HomeScreen`, so it runs only while Home is mounted.
///
/// Search is skipped: its recursive crawl is too heavy to repeat just to
/// probe the server.

@ProviderFor(reachabilityWatcher)
final reachabilityWatcherProvider = ReachabilityWatcherProvider._();

/// US-JX-20: notices a Jenkins outage (or its return) while Home is already
/// on screen — on a timer, and when the app comes back to the foreground.
/// Watched by `HomeScreen`, so it runs only while Home is mounted.
///
/// Search is skipped: its recursive crawl is too heavy to repeat just to
/// probe the server.

final class ReachabilityWatcherProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// US-JX-20: notices a Jenkins outage (or its return) while Home is already
  /// on screen — on a timer, and when the app comes back to the foreground.
  /// Watched by `HomeScreen`, so it runs only while Home is mounted.
  ///
  /// Search is skipped: its recursive crawl is too heavy to repeat just to
  /// probe the server.
  ReachabilityWatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reachabilityWatcherProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reachabilityWatcherHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return reachabilityWatcher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$reachabilityWatcherHash() =>
    r'b97b852325be1c5652e7f2ce9a3b37747c0eccf1';
