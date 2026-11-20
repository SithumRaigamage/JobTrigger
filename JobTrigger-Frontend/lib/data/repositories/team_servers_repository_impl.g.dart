// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_servers_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(teamServersRepository)
final teamServersRepositoryProvider = TeamServersRepositoryProvider._();

final class TeamServersRepositoryProvider
    extends
        $FunctionalProvider<
          TeamServersRepository,
          TeamServersRepository,
          TeamServersRepository
        >
    with $Provider<TeamServersRepository> {
  TeamServersRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamServersRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamServersRepositoryHash();

  @$internal
  @override
  $ProviderElement<TeamServersRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TeamServersRepository create(Ref ref) {
    return teamServersRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeamServersRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeamServersRepository>(value),
    );
  }
}

String _$teamServersRepositoryHash() =>
    r'8425201e94af384dc112097ef54118c34f7c7b72';
