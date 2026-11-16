// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The unified home dashboard (`NR-02`, `docs/implemented/improvement-plan.md`): failing
/// builds, running jobs and pinned items across Jenkins, GitHub Actions and
/// SonarQube on one screen.
///
/// Each tool is fetched independently and failures are reported per tool, so
/// a server that is down or a tool that was never set up leaves the rest of
/// the screen working. Read-only: it never triggers, cancels or approves
/// anything — those stay in each tool's own screens, and Jenkins keeps its
/// existing behaviour (`CLAUDE.md` §11).

@ProviderFor(DashboardNotifier)
final dashboardNotifierProvider = DashboardNotifierProvider._();

/// The unified home dashboard (`NR-02`, `docs/implemented/improvement-plan.md`): failing
/// builds, running jobs and pinned items across Jenkins, GitHub Actions and
/// SonarQube on one screen.
///
/// Each tool is fetched independently and failures are reported per tool, so
/// a server that is down or a tool that was never set up leaves the rest of
/// the screen working. Read-only: it never triggers, cancels or approves
/// anything — those stay in each tool's own screens, and Jenkins keeps its
/// existing behaviour (`CLAUDE.md` §11).
final class DashboardNotifierProvider
    extends $AsyncNotifierProvider<DashboardNotifier, DashboardData> {
  /// The unified home dashboard (`NR-02`, `docs/implemented/improvement-plan.md`): failing
  /// builds, running jobs and pinned items across Jenkins, GitHub Actions and
  /// SonarQube on one screen.
  ///
  /// Each tool is fetched independently and failures are reported per tool, so
  /// a server that is down or a tool that was never set up leaves the rest of
  /// the screen working. Read-only: it never triggers, cancels or approves
  /// anything — those stay in each tool's own screens, and Jenkins keeps its
  /// existing behaviour (`CLAUDE.md` §11).
  DashboardNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardNotifierHash();

  @$internal
  @override
  DashboardNotifier create() => DashboardNotifier();
}

String _$dashboardNotifierHash() => r'e489ab53ee84fe3bed51aca4ac74e1240c5e668d';

/// The unified home dashboard (`NR-02`, `docs/implemented/improvement-plan.md`): failing
/// builds, running jobs and pinned items across Jenkins, GitHub Actions and
/// SonarQube on one screen.
///
/// Each tool is fetched independently and failures are reported per tool, so
/// a server that is down or a tool that was never set up leaves the rest of
/// the screen working. Read-only: it never triggers, cancels or approves
/// anything — those stay in each tool's own screens, and Jenkins keeps its
/// existing behaviour (`CLAUDE.md` §11).

abstract class _$DashboardNotifier extends $AsyncNotifier<DashboardData> {
  FutureOr<DashboardData> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DashboardData>, DashboardData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DashboardData>, DashboardData>,
              AsyncValue<DashboardData>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
