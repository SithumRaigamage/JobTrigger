import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/credentials_repository_impl.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/credential/credentials_repository.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/jenkins/pending_input.dart';
import 'package:job_trigger/domain/jenkins/pipeline_stage.dart';
import 'package:job_trigger/domain/jenkins/test_report.dart';
import 'package:job_trigger/presentation/common_widgets/toast_controller.dart';
import 'package:job_trigger/presentation/features/job_detail/job_detail_screen.dart';
import 'package:job_trigger/presentation/features/job_detail/job_enabled_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_jenkins_repository.dart';

const _url = 'https://ci.test/job/api/';

class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.status);

  final int status;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString('', status);
  }

  @override
  void close({bool force = false}) {}
}

class _Repo extends FakeJenkinsRepository {
  _Repo({this.buildable = true, this.toggleResult = const Ok(null)});

  bool buildable;
  final Result<void, AppFailure> toggleResult;

  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobDetail(String jobUrl) async =>
      Ok(JenkinsJob(name: 'api', url: _url, buildable: buildable));

  @override
  Future<Result<void, AppFailure>> setJobEnabled(
    String jobUrl, {
    required bool enabled,
  }) async {
    if (toggleResult is Ok) buildable = enabled;
    return toggleResult;
  }

  @override
  Future<Result<TestReport?, AppFailure>> fetchTestReport(String b) async =>
      const Ok(null);

  @override
  Future<Result<List<PipelineStage>?, AppFailure>> fetchPipelineStages(
    String b,
  ) async => const Ok(null);

  @override
  Future<Result<PendingInput?, AppFailure>> fetchPendingInput(String b) async =>
      const Ok(null);
}

class _NoServers implements CredentialsRepository {
  @override
  Future<Result<List<JenkinsServer>, AppFailure>> fetchAll() async =>
      const Ok([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('repository (US-JX-13)', () {
    JenkinsRepositoryImpl repo(_StatusAdapter adapter) => JenkinsRepositoryImpl(
      Dio(BaseOptions(baseUrl: 'https://ci.test'))..httpClientAdapter = adapter,
    );

    test('disable POSTs {job}disable and accepts the 302', () async {
      final adapter = _StatusAdapter(302);
      final result = await repo(adapter).setJobEnabled(_url, enabled: false);
      expect(adapter.last?.path, '${_url}disable');
      expect(result, isA<Ok<void, AppFailure>>());
    });

    test('triggering a disabled job (409) is JobDisabledFailure', () async {
      final result = await repo(
        _StatusAdapter(409),
      ).triggerBuild(_url, isParameterized: false);
      expect(
        (result as Err<String?, AppFailure>).error,
        isA<JobDisabledFailure>(),
      );
    });
  });

  test('a refused toggle explains the multibranch case', () async {
    final container = ProviderContainer(
      overrides: [
        jenkinsRepositoryProvider.overrideWithValue(
          _Repo(toggleResult: const Err(PermissionFailure())),
        ),
      ],
    );
    addTearDown(container.dispose);
    container
      ..listen(jobEnabledNotifierProvider(_url), (_, _) {})
      ..listen(currentToastProvider, (_, _) {});

    await container
        .read(jobEnabledNotifierProvider(_url).notifier)
        .setEnabled(enabled: false, label: 'main');

    expect(
      container.read(currentToastProvider)?.message,
      contains('managed by its multibranch project'),
    );
  });

  testWidgets('a disabled job says so and cannot be triggered; enable works', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repo = _Repo(buildable: false);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          jenkinsRepositoryProvider.overrideWithValue(repo),
          credentialsRepositoryProvider.overrideWithValue(_NoServers()),
        ],
        child: const MaterialApp(
          home: JobDetailScreen(
            job: JenkinsJob(name: 'api', url: _url),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('This job is disabled'), findsOneWidget);
    final trigger = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Disabled'),
    );
    expect(trigger.onPressed, isNull);

    await tester.tap(find.byTooltip('Job options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enable job'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enable'));
    await tester.pumpAndSettle();

    expect(find.textContaining('This job is disabled'), findsNothing);
    expect(find.text('Trigger Build'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4)); // toast auto-dismiss
  });
}
