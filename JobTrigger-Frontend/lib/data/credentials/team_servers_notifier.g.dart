// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_servers_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-SUB-11 AC17: the team's shared Jenkins servers, for Settings and for
/// `ActiveServerNotifier` (which restores an active team server on restart
/// and falls back when it stops being shared).

@ProviderFor(TeamServersNotifier)
final teamServersNotifierProvider = TeamServersNotifierProvider._();

/// US-SUB-11 AC17: the team's shared Jenkins servers, for Settings and for
/// `ActiveServerNotifier` (which restores an active team server on restart
/// and falls back when it stops being shared).
final class TeamServersNotifierProvider
    extends $AsyncNotifierProvider<TeamServersNotifier, List<TeamServer>> {
  /// US-SUB-11 AC17: the team's shared Jenkins servers, for Settings and for
  /// `ActiveServerNotifier` (which restores an active team server on restart
  /// and falls back when it stops being shared).
  TeamServersNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: noRetry,
        name: r'teamServersNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamServersNotifierHash();

  @$internal
  @override
  TeamServersNotifier create() => TeamServersNotifier();
}

String _$teamServersNotifierHash() =>
    r'04be9ad4c5a3cb6e2ea0fe68315a4d8778562967';

/// US-SUB-11 AC17: the team's shared Jenkins servers, for Settings and for
/// `ActiveServerNotifier` (which restores an active team server on restart
/// and falls back when it stops being shared).

abstract class _$TeamServersNotifier extends $AsyncNotifier<List<TeamServer>> {
  FutureOr<List<TeamServer>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<TeamServer>>, List<TeamServer>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<TeamServer>>, List<TeamServer>>,
              AsyncValue<List<TeamServer>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
