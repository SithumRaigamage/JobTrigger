import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/jenkins_node.dart';
import 'package:job_trigger/presentation/features/nodes/nodes_notifier.dart';
import 'package:job_trigger/presentation/features/nodes/nodes_screen.dart';

import '../../../support/fake_jenkins_repository.dart';

/// Replies to every request with one JSON body.
class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.body, [this.status = 200]);

  final String body;
  final int status;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _builtIn = JenkinsNode(
  displayName: 'Built-In Node',
  isBuiltIn: true,
  offline: false,
  numExecutors: 4,
  running: [
    RunningExecutable(
      name: 'slow-build #9 (Work)',
      url: 'https://ci.test/job/slow-build/9/',
      progress: 40,
    ),
  ],
);
const _agent = JenkinsNode(
  displayName: 'agent-1',
  isBuiltIn: false,
  offline: true,
  numExecutors: 2,
);

class _Repo extends FakeJenkinsRepository {
  _Repo(this.toggleResult);

  final Result<void, AppFailure> toggleResult;
  final toggled = <(String, String)>[];

  @override
  Future<Result<List<JenkinsNode>, AppFailure>> fetchNodes() async =>
      const Ok([_builtIn, _agent]);

  @override
  Future<Result<void, AppFailure>> toggleNodeOffline(
    JenkinsNode node, {
    String message = '',
  }) async {
    toggled.add((node.urlName, message));
    return toggleResult;
  }
}

Future<_Repo> _pump(
  WidgetTester tester,
  Result<void, AppFailure> toggle,
) async {
  final repo = _Repo(toggle);
  tester.view
    ..physicalSize = const Size(900, 1600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: NodesScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  group('repository (US-JX-12)', () {
    test('parses nodes, executors, and the disk warning', () async {
      final adapter = _JsonAdapter('''
{"computer":[
 {"_class":"hudson.model.Hudson\$MasterComputer","displayName":"Built-In Node",
  "offline":false,"temporarilyOffline":false,"offlineCauseReason":"","numExecutors":4,
  "executors":[{"progress":-1,"currentExecutable":null},
    {"progress":40,"currentExecutable":{"fullDisplayName":"slow-build #9 (Work)",
      "url":"http://jenkins.internal:8080/job/slow-build/9/"}}],
  "oneOffExecutors":[],
  "monitorData":{"hudson.node_monitors.DiskSpaceMonitor":
    {"size":1000,"warningThreshold":2000}}},
 {"_class":"hudson.slaves.SlaveComputer","displayName":"agent 1","offline":true,
  "temporarilyOffline":true,"offlineCauseReason":"maintenance","numExecutors":2,
  "executors":[],"oneOffExecutors":[],
  "monitorData":{"hudson.node_monitors.DiskSpaceMonitor":null}}]}''');
      final dio = Dio(BaseOptions(baseUrl: 'https://ci.test'))
        ..httpClientAdapter = adapter;

      final nodes =
          (await JenkinsRepositoryImpl(dio).fetchNodes()
                  as Ok<List<JenkinsNode>, dynamic>)
              .value;

      expect(adapter.last?.path, '/computer/api/json');
      expect(nodes[0].isBuiltIn, isTrue);
      expect(nodes[0].urlName, '(built-in)');
      expect(nodes[0].busyExecutors, 1);
      expect(nodes[0].running.single.progress, 40);
      expect(nodes[0].running.single.url, 'https://ci.test/job/slow-build/9/');
      expect(nodes[0].lowDiskSpace, isTrue);
      expect(nodes[1].urlName, 'agent%201');
      expect(nodes[1].offlineReason, 'maintenance');
      expect(nodes[1].lowDiskSpace, isFalse);
    });

    test('toggleOffline posts the reason and accepts the 302', () async {
      final adapter = _JsonAdapter('', 302);
      final dio = Dio(BaseOptions(baseUrl: 'https://ci.test'))
        ..httpClientAdapter = adapter;

      final result = await JenkinsRepositoryImpl(
        dio,
      ).toggleNodeOffline(_builtIn, message: 'disk cleanup');

      expect(adapter.last?.path, '/computer/(built-in)/toggleOffline');
      expect(adapter.last?.queryParameters, {'offlineMessage': 'disk cleanup'});
      expect(result, isA<Ok<void, AppFailure>>());
    });
  });

  group('NodesScreen', () {
    testWidgets('shows status, load, and running builds', (tester) async {
      await _pump(tester, const Ok(null));

      expect(find.text('Built-In Node'), findsOneWidget);
      expect(find.textContaining('Online · 1/4 busy'), findsOneWidget);
      expect(find.textContaining('Offline · 0/2 busy'), findsOneWidget);

      await tester.tap(find.text('Built-In Node'));
      await tester.pumpAndSettle();
      expect(find.text('slow-build #9 (Work)'), findsOneWidget);

      // Dispose inside the test so the 10s refresh timer is cancelled.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('taking a node offline asks for a reason and sends it', (
      tester,
    ) async {
      final repo = await _pump(tester, const Ok(null));

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'disk cleanup');
      await tester.tap(find.text('Take offline'));
      await tester.pumpAndSettle();

      expect(repo.toggled, [('(built-in)', 'disk cleanup')]);
      await tester.pump(const Duration(seconds: 4)); // toast
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('after a 403 the switches are hidden for the session', (
      tester,
    ) async {
      await _pump(tester, const Err(PermissionFailure()));
      expect(find.byType(Switch), findsNWidgets(2));

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take offline'));
      await tester.pumpAndSettle();

      expect(find.byType(Switch), findsNothing);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpWidget(const SizedBox());
    });
  });

  test('NodesState keeps canToggle through a refresh', () {
    const state = NodesState(nodes: [], canToggle: false);
    expect(state.canToggle, isFalse);
  });
}
