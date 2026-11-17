import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/presentation/features/dashboard/dashboard_notifier.dart';
import 'package:job_trigger/presentation/features/dashboard/dashboard_screen.dart';

class _FakeDashboard extends DashboardNotifier {
  _FakeDashboard(this.data);

  final DashboardData data;

  @override
  Future<DashboardData> build() async => data;
}

const _job = JenkinsJob(
  name: 'web',
  url: 'https://a.test/job/web/',
  color: 'red',
);

Future<void> _pump(WidgetTester tester, DashboardData data) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dashboardNotifierProvider.overrideWith(() => _FakeDashboard(data)),
      ],
      child: const MaterialApp(home: DashboardScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('groups rows and sums them up in the header', (tester) async {
    const data = DashboardData(
      items: [
        DashboardItem(
          group: DashboardGroup.failing,
          source: DashboardSource.jenkins,
          title: 'web',
          subtitle: 'Home · #12',
          jenkinsJob: _job,
        ),
        DashboardItem(
          group: DashboardGroup.running,
          source: DashboardSource.jenkins,
          title: 'api',
          subtitle: '#7',
        ),
      ],
      failingCount: 1,
      runningCount: 1,
    );

    await _pump(tester, data);

    expect(find.text('1 failing · 1 running'), findsOneWidget);
    expect(find.text('Failing and broken'), findsOneWidget);
    expect(find.text('Running now'), findsOneWidget);
    expect(find.text('web'), findsOneWidget);
    expect(find.text('api'), findsOneWidget);
  });

  testWidgets('empty state names the tools that are not set up', (
    tester,
  ) async {
    await _pump(
      tester,
      const DashboardData(notSetUp: {DashboardSource.jenkins}),
    );

    expect(find.text('Nothing needs you right now'), findsOneWidget);
    expect(find.text('Jenkins isn’t set up on this device.'), findsOneWidget);
  });

  testWidgets('a tool that failed is a note, not a dead screen', (
    tester,
  ) async {
    const data = DashboardData(
      items: [
        DashboardItem(
          group: DashboardGroup.failing,
          source: DashboardSource.jenkins,
          title: 'web',
          subtitle: 'Home · #12',
          jenkinsJob: _job,
        ),
      ],
      failingCount: 1,
      failures: {DashboardSource.githubActions: NetworkFailure()},
    );

    await _pump(tester, data);

    expect(find.text('web'), findsOneWidget);
    expect(find.textContaining("Can't reach the server"), findsOneWidget);
  });
}
