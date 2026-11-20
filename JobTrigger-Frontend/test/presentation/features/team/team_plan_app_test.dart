import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/platform/link_launcher.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/billing/revenuecat_billing_client.dart';
import 'package:job_trigger/data/credentials/active_server_notifier.dart';
import 'package:job_trigger/data/credentials/team_servers_notifier.dart';
import 'package:job_trigger/data/repositories/credentials_repository_impl.dart';
import 'package:job_trigger/data/repositories/subscription_repository_impl.dart';
import 'package:job_trigger/data/repositories/team_servers_repository_impl.dart';
import 'package:job_trigger/domain/auth/auth_state.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/domain/credential/credentials_repository.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/subscription/subscription_status.dart';
import 'package:job_trigger/domain/team/team_server.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/settings/team_servers_section.dart';
import 'package:job_trigger/presentation/features/subscription/subscription_screen.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_subscription.dart';

// US-SUB-11 AC16 (plan screen) and AC17 (team servers) in the app.

class _Auth extends AuthNotifier {
  @override
  Future<AuthState> build() async =>
      const Authenticated(User(id: 'u2', email: 'dev@example.com'));
}

SubscriptionSnapshot _teamSnapshot({bool owner = false, bool active = true}) =>
    SubscriptionSnapshot(
      entitlements: proSnapshot.entitlements,
      status: SubscriptionStatus(
        state: SubscriptionState.active,
        source: SubscriptionSource.team,
        willRenew: true,
        team: TeamMembership(
          id: 't1',
          name: 'Platform',
          isOwner: owner,
          active: active,
        ),
      ),
    );

const _own = JenkinsServer(
  id: 'own1',
  serverName: 'my-ci',
  jenkinsURL: 'https://mine.example.com',
  username: 'me',
  secret: 's',
  isDefault: true,
);

const _shared = TeamServer(
  server: JenkinsServer(
    id: 'team:c1',
    serverName: 'prod-ci',
    jenkinsURL: 'https://ci.example.com',
    username: 'svc',
    secret: 'p4ssword',
  ),
  sharedBy: 'owner@example.com',
);

class _Own implements CredentialsRepository {
  _Own(this.servers);
  final List<JenkinsServer> servers;

  @override
  Future<Result<List<JenkinsServer>, AppFailure>> fetchAll() async =>
      Ok(servers);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Team implements TeamServersRepository {
  _Team(this.servers);
  List<TeamServer> servers;
  int calls = 0;

  @override
  Future<Result<List<TeamServer>, AppFailure>> fetchShared() async {
    calls++;
    return Ok(servers);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Subscription screen (AC16)', () {
    Future<void> pump(
      WidgetTester tester,
      SubscriptionSnapshot snapshot,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 1600)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionRepositoryProvider.overrideWithValue(
              FakeSubscriptionRepository(loadResult: Ok(snapshot)),
            ),
            billingClientProvider.overrideWithValue(FakeBillingClient()),
            authNotifierProvider.overrideWith(_Auth.new),
            linkLauncherProvider.overrideWithValue((_) async => true),
          ],
          child: MaterialApp.router(
            theme: AppTheme.dark(),
            routerConfig: GoRouter(
              initialLocation: AppRoutes.subscription,
              routes: [
                GoRoute(
                  path: AppRoutes.subscription,
                  builder: (_, _) => const SubscriptionScreen(),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a member: Pro through the team, nothing to buy or link', (
      tester,
    ) async {
      await pump(tester, _teamSnapshot());

      expect(find.text('JobTrigger Pro'), findsOneWidget);
      expect(
        find.text("Pro through Platform. Your team's owner manages this plan."),
        findsOneWidget,
      );
      expect(find.text('Upgrade to Pro'), findsNothing);
      expect(find.text('Restore purchases'), findsNothing);
      expect(find.textContaining('Manage in the'), findsNothing);
      expect(find.text('Verify student status'), findsNothing);
    });

    testWidgets('the owner is told it is managed on the website', (
      tester,
    ) async {
      await pump(tester, _teamSnapshot(owner: true));
      expect(
        find.text(
          'Pro through Platform. You manage the team on the JobTrigger '
          'website.',
        ),
        findsOneWidget,
      );
      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('Team servers (AC17)', () {
    Future<(ProviderContainer, _Team)> pump(
      WidgetTester tester, {
      SubscriptionSnapshot? snapshot,
      List<TeamServer>? shared,
    }) async {
      final team = _Team(shared ?? [_shared]);
      tester.view
        ..physicalSize = const Size(800, 1600)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionRepositoryProvider.overrideWithValue(
              FakeSubscriptionRepository(
                loadResult: Ok(snapshot ?? _teamSnapshot()),
              ),
            ),
            billingClientProvider.overrideWithValue(FakeBillingClient()),
            authNotifierProvider.overrideWith(_Auth.new),
            credentialsRepositoryProvider.overrideWithValue(_Own([_own])),
            teamServersRepositoryProvider.overrideWithValue(team),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: TeamServersSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(TeamServersSection)),
      );
      return (container, team);
    }

    testWidgets('lists shared servers; Use makes one active', (tester) async {
      final (container, _) = await pump(tester);
      container.listen(activeServerNotifierProvider, (_, _) {});

      expect(find.text('TEAM SERVERS'), findsOneWidget);
      expect(find.textContaining('Shared by Platform'), findsOneWidget);
      expect(find.text('prod-ci'), findsOneWidget);
      expect(
        find.textContaining('Shared by owner@example.com'),
        findsOneWidget,
      );
      // Read-only: no edit or delete in the app.
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);

      await tester.tap(find.bySemanticsLabel('Use prod-ci'));
      await tester.pumpAndSettle();

      expect(container.read(activeServerNotifierProvider)?.id, 'team:c1');
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('hidden, and never fetched, without an active team', (
      tester,
    ) async {
      final (_, team) = await pump(tester, snapshot: proSnapshot);
      expect(find.byKey(const Key('team_servers_section')), findsNothing);
      expect(team.calls, 0);

      final (_, lapsed) = await pump(
        tester,
        snapshot: _teamSnapshot(active: false),
      );
      expect(find.byKey(const Key('team_servers_section')), findsNothing);
      expect(lapsed.calls, 0);
    });

    testWidgets('says so when nothing is shared yet', (tester) async {
      await pump(tester, shared: const []);
      expect(
        find.textContaining("hasn't shared any Jenkins servers"),
        findsOneWidget,
      );
    });
  });

  group('ActiveServerNotifier with team servers (AC17)', () {
    ProviderContainer container(_Team team, List<JenkinsServer> own) {
      final c = ProviderContainer(
        overrides: [
          credentialsRepositoryProvider.overrideWithValue(_Own(own)),
          teamServersRepositoryProvider.overrideWithValue(team),
        ],
      );
      addTearDown(c.dispose);
      c.listen(activeServerNotifierProvider, (_, _) {});
      return c;
    }

    Future<void> settle() =>
        Future<void>.delayed(const Duration(milliseconds: 20));

    test('restores a still-shared team server on restart', () async {
      SharedPreferences.setMockInitialValues({'active_server_id': 'team:c1'});
      final c = container(_Team([_shared]), [_own]);
      await settle();
      expect(c.read(activeServerNotifierProvider)?.id, 'team:c1');
    });

    test('restores it for someone with no servers of their own', () async {
      SharedPreferences.setMockInitialValues({'active_server_id': 'team:c1'});
      final c = container(_Team([_shared]), const []);
      await settle();
      expect(c.read(activeServerNotifierProvider)?.id, 'team:c1');
    });

    test('falls back to the own default once it is no longer shared', () async {
      SharedPreferences.setMockInitialValues({'active_server_id': 'team:c1'});
      final team = _Team([_shared]);
      final c = container(team, [_own]);
      c.listen(teamServersNotifierProvider, (_, _) {});
      await settle();
      expect(c.read(activeServerNotifierProvider)?.id, 'team:c1');

      team.servers = const [];
      await c.read(teamServersNotifierProvider.notifier).refresh();
      await settle();
      expect(c.read(activeServerNotifierProvider)?.id, 'own1');
    });

    test('an unshared team server on restart gives the own default', () async {
      SharedPreferences.setMockInitialValues({'active_server_id': 'team:gone'});
      final c = container(_Team([_shared]), [_own]);
      await settle();
      expect(c.read(activeServerNotifierProvider)?.id, 'own1');
    });
  });
}
