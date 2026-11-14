import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import '../../domain/jenkins/branch_kind.dart';
import '../../domain/jenkins/build_artifact.dart';
import '../../domain/jenkins/health_report.dart';
import '../../domain/jenkins/history_filter.dart';
import '../../domain/jenkins/jenkins_build.dart';
import '../../domain/jenkins/jenkins_job.dart';
import '../../domain/jenkins/jenkins_node.dart';
import '../../domain/jenkins/jenkins_repository.dart';
import '../../domain/jenkins/jenkins_view.dart';
import '../../domain/jenkins/job_property.dart';
import '../../domain/jenkins/log_chunk.dart';
import '../../domain/jenkins/parameter_definition.dart';
import '../../domain/jenkins/parameter_file.dart';
import '../../domain/jenkins/pending_input.dart';
import '../../domain/jenkins/pipeline_stage.dart';
import '../../domain/jenkins/queue_entry.dart';
import '../../domain/jenkins/queue_item.dart';
import '../../domain/jenkins/scm_change.dart';
import '../../domain/jenkins/server_status.dart';
import '../../domain/jenkins/test_report.dart';
import 'demo_data.dart';
import 'demo_mode_notifier.dart';

part 'demo_jenkins_repository.g.dart';

const _base = demoJenkinsBaseUrl;
const _appUrl = '${_base}job/demo-app/';
const _mainUrl = '${_appUrl}job/main/';
const _featureUrl = '${_appUrl}job/feature-login/';
const _prUrl = '${_appUrl}job/PR-42/';
const _platformUrl = '${_base}job/platform/';
const _deployUrl = '${_platformUrl}job/deploy-staging/';
const _nightlyUrl = '${_platformUrl}job/nightly-tests/';
const _docsUrl = '${_base}job/docs-site/';

/// How long the scripted "Trigger build" run waits in the queue, and then runs.
/// About 20 seconds end to end, which is long enough to watch the stages
/// advance and the log stream, and short enough not to wait on.
const demoQueueWait = Duration(seconds: 2);
const demoRunLength = Duration(seconds: 18);

/// The one scripted run, `demo-app/main` (E2, PE-13): queued, then five
/// stages and a log that grows line by line, then SUCCESS. Everything is
/// derived from the time since "Trigger build", so there is no timer to leak.
class DemoBuildScript {
  DemoBuildScript(this.number, this.triggeredAt);

  final int number;
  final DateTime triggeredAt;

  String get buildUrl => '$_mainUrl$number/';
  String get queueUrl => '${_base}queue/item/$number/';

  Duration elapsed(DateTime now) => now.difference(triggeredAt);
  bool isQueued(DateTime now) => elapsed(now) < demoQueueWait;
  bool isDone(DateTime now) => elapsed(now) >= demoQueueWait + demoRunLength;
  DateTime get startedAt => triggeredAt.add(demoQueueWait);

  /// Seconds into the run, clamped to its length.
  int runSeconds(DateTime now) {
    final seconds = (elapsed(now) - demoQueueWait).inMilliseconds / 1000;
    return seconds.clamp(0, demoRunLength.inSeconds).floor();
  }

  static const _stages = [
    ('Checkout', 0, 2),
    ('Build', 2, 7),
    ('Test', 7, 12),
    ('Package', 12, 15),
    ('Deploy', 15, 18),
  ];

  List<PipelineStage> stages(DateTime now) {
    final seconds = runSeconds(now);
    final done = isDone(now);
    return [
      for (final (i, (name, from, to)) in _stages.indexed)
        PipelineStage(
          id: '${10 + i}',
          name: name,
          status: done || seconds >= to
              ? 'SUCCESS'
              : seconds >= from
              ? 'IN_PROGRESS'
              : 'NOT_EXECUTED',
          startTimeMillis: startedAt.millisecondsSinceEpoch + from * 1000,
          durationMillis: done || seconds >= to
              ? (to - from) * 1000
              : seconds >= from
              ? (seconds - from) * 1000
              : null,
        ),
    ];
  }

  static const _lines = [
    (0, 'Started by user demo'),
    (0, '[Pipeline] stage (Checkout)'),
    (1, 'Cloning https://git.example.invalid/demo-org/app.git'),
    (2, '[Pipeline] stage (Build)'),
    (3, '+ npm ci'),
    (4, 'added 612 packages in 3s'),
    (5, '+ npm run build'),
    (6, 'Compiled successfully.'),
    (7, '[Pipeline] stage (Test)'),
    (8, '+ npm test'),
    (9, 'PASS src/login.test.ts'),
    (10, 'PASS src/builds.test.ts'),
    (11, 'Tests: 128 passed, 128 total'),
    (12, '[Pipeline] stage (Package)'),
    (13, '+ docker build -t demo-app:latest .'),
    (14, 'Successfully tagged demo-app:latest'),
    (15, '[Pipeline] stage (Deploy)'),
    (16, '+ ./deploy.sh staging'),
    (17, 'Deployed demo-app to staging.'),
    (18, 'Finished: SUCCESS'),
  ];

  String log(DateTime now) {
    if (isQueued(now)) return '';
    final seconds = runSeconds(now);
    final buffer = StringBuffer();
    for (final (at, line) in _lines) {
      if (at <= seconds || isDone(now)) buffer.writeln(line);
    }
    return buffer.toString();
  }

  JenkinsBuild build(DateTime now) {
    final done = isDone(now);
    return JenkinsBuild(
      number: number,
      url: buildUrl,
      result: done ? 'SUCCESS' : null,
      building: !done,
      timestamp: startedAt.millisecondsSinceEpoch.toDouble(),
      duration: done ? demoRunLength.inMilliseconds.toDouble() : null,
      estimatedDuration: demoRunLength.inMilliseconds.toDouble(),
      causes: const ['Started by user demo'],
      startedByUserIds: const ['demo'],
    );
  }
}

/// The demo's Jenkins (E2, PE-10): fixed sample data in memory, answering
/// the same interface as the real repository, so no widget changes. It
/// makes no request. Reads are real-looking; writes answer
/// [DemoUnavailableFailure] except the scripted run on `demo-app/main`.
class DemoJenkinsRepository implements JenkinsRepository {
  DemoJenkinsRepository({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _t0 = _clock();
    _seed();
  }

  final DateTime Function() _clock;
  late final DateTime _t0;
  DemoBuildScript? _script;

  // url → job (leaf jobs and folders), and child urls per folder.
  final Map<String, JenkinsJob> _jobs = {};
  final Map<String, List<String>> _children = {};
  final Map<String, List<JenkinsBuild>> _builds = {};
  final Map<String, String> _logs = {};
  final Map<String, List<PipelineStage>> _stageLists = {};
  final Map<String, TestReport> _reports = {};

  static const _unavailable = Err<void, AppFailure>(DemoUnavailableFailure());

  double _ago(Duration d) => _t0.subtract(d).millisecondsSinceEpoch.toDouble();

  JenkinsBuild _b(
    String jobUrl,
    int n,
    String? result,
    Duration ago,
    int durationMs, {
    bool building = false,
    List<String> causes = const ['Started by user demo'],
    List<ScmChange> changes = const [],
    Map<String, String> parameters = const {},
    List<BuildArtifact> artifacts = const [],
  }) => JenkinsBuild(
    number: n,
    url: '$jobUrl$n/',
    result: result,
    building: building,
    timestamp: _ago(ago),
    duration: building ? null : durationMs.toDouble(),
    estimatedDuration: 240000,
    causes: causes,
    changes: changes,
    parameterValues: parameters,
    artifacts: artifacts,
    startedByUserIds: const ['demo'],
  );

  void _seed() {
    // demo-app/main: a healthy branch with eight builds. #42 is the
    // scripted run.
    _addJob(
      _mainUrl,
      'main',
      color: 'blue',
      builds: [
        for (var n = 41; n >= 34; n--)
          _b(
            _mainUrl,
            n,
            n == 37 ? 'FAILURE' : 'SUCCESS',
            Duration(hours: 2 + (41 - n) * 7),
            n == 37 ? 61000 : 198000,
            causes: n.isEven
                ? const ['Started by an SCM change']
                : const ['Started by user demo'],
            changes: const [
              ScmChange(
                author: 'Priya N.',
                message: 'Show build duration on the job screen',
              ),
              ScmChange(author: 'Sam O.', message: 'Bump dependencies'),
            ],
          ),
      ],
      health: 80,
    );
    // demo-app/feature-login: the failed build with a readable log.
    _addJob(
      _featureUrl,
      'feature-login',
      color: 'red',
      builds: [
        _b(
          _featureUrl,
          7,
          'FAILURE',
          const Duration(hours: 5),
          94000,
          changes: const [
            ScmChange(
              author: 'Maria K.',
              message: 'Validate an empty password on the login form',
            ),
          ],
        ),
        _b(_featureUrl, 6, 'SUCCESS', const Duration(days: 1), 180000),
      ],
      health: 40,
    );
    _addJob(
      _prUrl,
      'PR-42',
      color: 'blue',
      builds: [_b(_prUrl, 3, 'SUCCESS', const Duration(hours: 9), 175000)],
      health: 100,
    );
    _addJob(
      _appUrl,
      'demo-app',
      jobClass: JenkinsJob.multibranchClass,
      color: 'blue',
      description: 'Sample multibranch pipeline: the app’s branches and PRs.',
      children: [_mainUrl, _featureUrl, _prUrl],
    );

    // platform/deploy-staging: a build that is running right now.
    _addJob(
      _deployUrl,
      'deploy-staging',
      color: 'blue_anime',
      description: 'Deploys the latest build to the staging cluster.',
      parameters: const [
        ParameterDefinition(
          name: 'ENVIRONMENT',
          type: 'ChoiceParameterDefinition',
          choices: ['staging', 'qa'],
          defaultValue: 'staging',
        ),
        ParameterDefinition(
          name: 'VERSION',
          type: 'StringParameterDefinition',
          defaultValue: 'latest',
        ),
      ],
      builds: [
        _b(
          _deployUrl,
          118,
          null,
          const Duration(seconds: 90),
          0,
          building: true,
          parameters: const {'ENVIRONMENT': 'staging', 'VERSION': 'latest'},
        ),
        _b(
          _deployUrl,
          117,
          'SUCCESS',
          const Duration(hours: 3),
          312000,
          parameters: const {'ENVIRONMENT': 'staging', 'VERSION': '1.8.2'},
        ),
      ],
      health: 80,
    );
    _addJob(
      _nightlyUrl,
      'nightly-tests',
      color: 'yellow',
      builds: [
        _b(
          _nightlyUrl,
          212,
          'UNSTABLE',
          const Duration(hours: 11),
          1260000,
          causes: const ['Started by timer'],
        ),
        _b(
          _nightlyUrl,
          211,
          'SUCCESS',
          const Duration(hours: 35),
          1204000,
          causes: const ['Started by timer'],
        ),
      ],
      health: 60,
    );
    _addJob(
      _platformUrl,
      'platform',
      jobClass: 'com.cloudbees.hudson.plugins.folder.Folder',
      description: 'Shared deployment and test jobs.',
      children: [_deployUrl, _nightlyUrl],
    );
    _addJob(
      _docsUrl,
      'docs-site',
      color: 'blue',
      builds: [
        _b(_docsUrl, 25, 'SUCCESS', const Duration(days: 2), 42000),
        _b(_docsUrl, 24, 'SUCCESS', const Duration(days: 4), 40000),
      ],
      health: 100,
    );
    _children[''] = [_appUrl, _platformUrl, _docsUrl];

    _logs['${_featureUrl}7/'] = _failedLog;
    _stageLists['${_featureUrl}7/'] = _stages(
      const [
        ('Checkout', 'SUCCESS', 3000),
        ('Build', 'SUCCESS', 21000),
        ('Test', 'FAILED', 64000),
        ('Package', 'NOT_EXECUTED', null),
      ],
      _ago(const Duration(hours: 5)),
      failureMessage: 'script returned exit code 1',
    );
    _reports['${_featureUrl}7/'] = const TestReport(
      passCount: 124,
      failCount: 2,
      skipCount: 1,
      failingTests: [
        FailingTest(
          name: 'rejects an empty password',
          className: 'login.LoginForm',
          errorDetails:
              'Expected the form to show "Enter your password", got nothing.',
          isNewFailure: true,
          durationSeconds: 0.04,
        ),
        FailingTest(
          name: 'keeps the email after a failed attempt',
          className: 'login.LoginForm',
          errorDetails: 'Expected "you@company.com", got "".',
          isNewFailure: true,
          durationSeconds: 0.02,
        ),
      ],
    );
    _logs['${_deployUrl}118/'] = _runningLog;
    _stageLists['${_deployUrl}118/'] = _stages(const [
      ('Checkout', 'SUCCESS', 3000),
      ('Build', 'SUCCESS', 28000),
      ('Deploy', 'IN_PROGRESS', 59000),
    ], _ago(const Duration(seconds: 90)));
    _logs['${_nightlyUrl}212/'] = _nightlyLog;
    _reports['${_nightlyUrl}212/'] = const TestReport(
      passCount: 940,
      failCount: 2,
      skipCount: 11,
      failingTests: [
        FailingTest(
          name: 'sync retries after a timeout',
          className: 'jobs.SyncTest',
          errorDetails: 'Timed out after 30s waiting for the retry.',
        ),
        FailingTest(
          name: 'renders the empty state',
          className: 'ui.QueueTest',
          errorDetails: 'Snapshot differs on line 14.',
        ),
      ],
    );
    for (final entry in _builds.entries) {
      for (final build in entry.value) {
        _logs.putIfAbsent(build.url, () => _okLog(build));
        _stageLists.putIfAbsent(
          build.url,
          () => build.url.startsWith(_docsUrl)
              ? const []
              : _stages(const [
                  ('Checkout', 'SUCCESS', 3000),
                  ('Build', 'SUCCESS', 52000),
                  ('Test', 'SUCCESS', 90000),
                  ('Deploy', 'SUCCESS', 20000),
                ], build.timestamp),
        );
      }
    }
  }

  List<PipelineStage> _stages(
    List<(String, String, int?)> rows,
    double startMs, {
    String? failureMessage,
  }) {
    var at = startMs.toInt();
    return [
      for (final (i, (name, status, duration)) in rows.indexed)
        () {
          final stage = PipelineStage(
            id: '${10 + i}',
            name: name,
            status: status,
            startTimeMillis: duration == null ? null : at,
            durationMillis: duration,
            errorMessage: status == 'FAILED' ? failureMessage : null,
          );
          at += duration ?? 0;
          return stage;
        }(),
    ];
  }

  void _addJob(
    String url,
    String name, {
    String? jobClass,
    String? color,
    String? description,
    List<JenkinsBuild> builds = const [],
    List<String> children = const [],
    int? health,
    List<ParameterDefinition>? parameters,
  }) {
    final lastBuild = builds.isEmpty ? null : builds.first;
    JenkinsBuild? lastWith(bool Function(JenkinsBuild) test) {
      for (final b in builds) {
        if (test(b)) return b;
      }
      return null;
    }

    _jobs[url] = JenkinsJob(
      name: name,
      url: url,
      jobClass: jobClass,
      description: description,
      color: color,
      buildable: children.isEmpty,
      lastBuild: lastBuild,
      lastSuccessfulBuild: lastWith((b) => b.result == 'SUCCESS'),
      lastFailedBuild: lastWith((b) => b.result == 'FAILURE'),
      healthReport: health == null
          ? const []
          : [
              HealthReport(
                description: 'Build stability',
                score: health,
                iconClassName: 'icon-health-60to79',
              ),
            ],
      property: parameters == null
          ? const []
          : [JobProperty(parameterDefinitions: parameters)],
      builds: builds,
    );
    _children[url] = children;
    _builds[url] = builds;
  }

  static String _okLog(JenkinsBuild build) =>
      'Started by user demo\n'
      '[Pipeline] stage (Checkout)\n'
      '[Pipeline] stage (Build)\n'
      '+ npm ci\n'
      '+ npm run build\n'
      'Compiled successfully.\n'
      '[Pipeline] stage (Test)\n'
      '+ npm test\n'
      'Tests: 128 passed, 128 total\n'
      '${build.result == 'FAILURE' ? 'ERROR: script returned exit code 1\n' : ''}'
      'Finished: ${build.result ?? 'SUCCESS'}\n';

  static const _failedLog =
      'Started by user demo\n'
      'Cloning https://git.example.invalid/demo-org/app.git\n'
      '[Pipeline] stage (Build)\n'
      '+ npm ci\n'
      'added 612 packages in 3s\n'
      '+ npm run build\n'
      'Compiled successfully.\n'
      '[Pipeline] stage (Test)\n'
      '+ npm test\n'
      'FAIL src/login.test.ts\n'
      '  ● LoginForm › rejects an empty password\n'
      '\n'
      '    Expected: "Enter your password"\n'
      '    Received: undefined\n'
      '\n'
      '  ● LoginForm › keeps the email after a failed attempt\n'
      '\n'
      '    Expected: "you@company.com"\n'
      '    Received: ""\n'
      '\n'
      'Tests: 2 failed, 124 passed, 126 total\n'
      'ERROR: script returned exit code 1\n'
      'Finished: FAILURE\n';

  static const _runningLog =
      'Started by user demo\n'
      '[Pipeline] stage (Checkout)\n'
      '[Pipeline] stage (Build)\n'
      '+ docker build -t demo-app:latest .\n'
      '[Pipeline] stage (Deploy)\n'
      '+ kubectl rollout status deployment/demo-app -n staging\n'
      'Waiting for deployment "demo-app" rollout to finish: 1 of 3 updated...\n';

  static const _nightlyLog =
      'Started by timer\n'
      '+ ./run-integration-tests.sh\n'
      'Tests: 2 failed, 940 passed, 11 skipped\n'
      'Build step marked the build as UNSTABLE\n'
      'Finished: UNSTABLE\n';

  DateTime get _now => _clock();

  /// Finished scripted runs become part of the job's history; a running one
  /// is shown too. The first [number] is one above the latest sample build.
  List<JenkinsBuild> _mainBuilds() {
    final script = _script;
    final base = _builds[_mainUrl]!;
    if (script == null || script.isQueued(_now)) return base;
    return [script.build(_now), ...base];
  }

  JenkinsJob _withLive(JenkinsJob job) {
    if (job.url != _mainUrl) return job;
    final builds = _mainBuilds();
    final last = builds.first;
    return job.copyWith(
      builds: builds,
      lastBuild: last,
      lastSuccessfulBuild: builds.firstWhere(
        (b) => b.result == 'SUCCESS',
        orElse: () => last,
      ),
    );
  }

  JenkinsJob _light(JenkinsJob job) => job.copyWith(builds: const []);

  JenkinsJob _tree(String url) {
    final job = _withLive(_jobs[url]!);
    final kids = _children[url]!;
    if (kids.isEmpty) return job;
    return job.copyWith(jobs: [for (final k in kids) _tree(k)]);
  }

  // --- reads ---------------------------------------------------------

  @override
  Future<Result<List<JenkinsView>, AppFailure>> fetchViews() async =>
      const Ok([JenkinsView(name: 'all', url: _base, isPrimary: true)]);

  @override
  Future<Result<ServerStatus, AppFailure>> fetchServerStatus() async =>
      const Ok(ServerStatus(version: '2.516.3'));

  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchJobTree() async =>
      Ok([for (final url in _children['']!) _tree(url)]);

  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchFolder(
    String? folderUrl,
  ) async {
    final kids = _children[folderUrl ?? ''];
    if (kids == null) return const Err(NotFoundFailure());
    return Ok([for (final url in kids) _light(_withLive(_jobs[url]!))]);
  }

  @override
  Future<Result<Map<String, BranchKind>, AppFailure>> fetchBranchKinds(
    String multibranchUrl,
  ) async => const Ok({
    'main': BranchKind.branch,
    'feature-login': BranchKind.branch,
    'PR-42': BranchKind.pullRequest,
  });

  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobDetail(String jobUrl) async {
    final job = _jobs[jobUrl];
    if (job == null) return const Err(NotFoundFailure());
    return Ok(_withLive(job));
  }

  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobStatus(String jobUrl) async {
    final job = _jobs[jobUrl];
    if (job == null) return const Err(NotFoundFailure());
    return Ok(_light(_withLive(job)));
  }

  JenkinsBuild? _findBuild(String buildUrl) {
    final script = _script;
    if (script != null && script.buildUrl == buildUrl) {
      return script.isQueued(_now) ? null : script.build(_now);
    }
    for (final list in _builds.values) {
      for (final build in list) {
        if (build.url == buildUrl) return build;
      }
    }
    return null;
  }

  String? _logFor(String buildUrl) {
    final script = _script;
    if (script != null && script.buildUrl == buildUrl) {
      return script.log(_now);
    }
    return _logs[buildUrl];
  }

  @override
  Future<Result<LogChunk, AppFailure>> streamBuildLog(
    String buildUrl, {
    int start = 0,
  }) async {
    final text = _logFor(buildUrl);
    if (text == null) return const Err(NotFoundFailure());
    final script = _script;
    final more = script != null && script.buildUrl == buildUrl
        ? !script.isDone(_now)
        : buildUrl == '${_deployUrl}118/';
    final from = start.clamp(0, text.length);
    return Ok(
      LogChunk(
        text: text.substring(from),
        nextOffset: text.length,
        hasMoreData: more,
      ),
    );
  }

  @override
  Future<Result<int, AppFailure>> fetchLogSize(String buildUrl) async {
    final text = _logFor(buildUrl);
    return text == null ? const Err(NotFoundFailure()) : Ok(text.length);
  }

  @override
  Future<Result<List<String>?, AppFailure>> fetchTimestamps(
    String buildUrl, {
    required int startLine,
    int? endLine,
  }) async => const Ok(null);

  @override
  Future<Result<void, AppFailure>> downloadConsoleText(
    String buildUrl,
    String savePath,
  ) async => _unavailable;

  @override
  Future<Result<List<JenkinsBuild>, AppFailure>> fetchJobHistory(
    String jobUrl, {
    int start = 0,
    int count = historyPageSize,
  }) async {
    final job = _jobs[jobUrl];
    if (job == null) return const Err(NotFoundFailure());
    final all = jobUrl == _mainUrl ? _mainBuilds() : _builds[jobUrl]!;
    if (start >= all.length) return const Ok([]);
    final end = (start + count).clamp(0, all.length);
    return Ok(all.sublist(start, end));
  }

  @override
  Future<Result<JenkinsBuild, AppFailure>> fetchBuildDetail(
    String buildUrl,
  ) async {
    final build = _findBuild(buildUrl);
    return build == null ? const Err(NotFoundFailure()) : Ok(build);
  }

  @override
  Future<Result<List<JenkinsNode>, AppFailure>> fetchNodes() async => const Ok([
    JenkinsNode(
      displayName: 'Built-In Node',
      isBuiltIn: true,
      offline: false,
      numExecutors: 2,
      diskFreeBytes: 48000000000,
      diskWarningBytes: 1000000000,
    ),
    JenkinsNode(
      displayName: 'linux-agent-1',
      isBuiltIn: false,
      offline: false,
      numExecutors: 4,
      running: [
        RunningExecutable(
          name: 'platform » deploy-staging #118',
          url: '${_deployUrl}118/',
          progress: 55,
        ),
      ],
      diskFreeBytes: 600000000,
      diskWarningBytes: 1000000000,
    ),
    JenkinsNode(
      displayName: 'mac-builder',
      isBuiltIn: false,
      offline: true,
      offlineReason: 'Disconnected for maintenance',
      numExecutors: 2,
    ),
  ]);

  @override
  Future<Result<List<QueueEntry>, AppFailure>> fetchQueue() async {
    final script = _script;
    if (script == null || !script.isQueued(_now)) return const Ok([]);
    return Ok([
      QueueEntry(
        id: script.number,
        taskName: 'demo-app » main',
        taskUrl: _mainUrl,
        why: 'Waiting for next available executor',
        inQueueSince: script.triggeredAt,
        taskColor: 'blue',
      ),
    ]);
  }

  @override
  Future<Result<QueueItem, AppFailure>> fetchQueueItem(
    String queueItemUrl,
  ) async {
    final script = _script;
    if (script == null || script.queueUrl != queueItemUrl) {
      return const Err(NotFoundFailure());
    }
    if (script.isQueued(_now)) {
      return const Ok(QueueItem(why: 'Waiting for next available executor'));
    }
    return Ok(
      QueueItem(
        executable: QueueExecutable(
          number: script.number,
          url: script.buildUrl,
        ),
      ),
    );
  }

  @override
  Future<Result<TestReport?, AppFailure>> fetchTestReport(
    String buildUrl,
  ) async {
    final script = _script;
    if (script != null && script.buildUrl == buildUrl) {
      return Ok(
        script.isDone(_now)
            ? const TestReport(passCount: 128, failCount: 0, skipCount: 0)
            : null,
      );
    }
    return Ok(_reports[buildUrl]);
  }

  @override
  Future<Result<int?, AppFailure>> fetchArtifactSize(
    String buildUrl,
    String relativePath,
  ) async => const Ok(null);

  @override
  Future<Result<void, AppFailure>> downloadArtifact(
    String buildUrl,
    String relativePath,
    String savePath, {
    void Function(int received, int? total)? onProgress,
  }) async => _unavailable;

  @override
  Future<Result<List<PipelineStage>?, AppFailure>> fetchPipelineStages(
    String buildUrl,
  ) async {
    final script = _script;
    if (script != null && script.buildUrl == buildUrl) {
      return Ok(script.isQueued(_now) ? null : script.stages(_now));
    }
    final stages = _stageLists[buildUrl];
    if (stages == null) return const Err(NotFoundFailure());
    return Ok(stages.isEmpty ? null : stages);
  }

  @override
  Future<Result<List<PipelineStep>?, AppFailure>> fetchStageSteps(
    String buildUrl,
    String stageId,
  ) async => const Ok(null);

  @override
  Future<Result<StepLog, AppFailure>> fetchStepLog(
    String buildUrl,
    String stepId,
  ) async => const Ok(StepLog(text: '', hasMore: false));

  @override
  Future<Result<PendingInput?, AppFailure>> fetchPendingInput(
    String buildUrl,
  ) async => const Ok(null);

  // --- writes: only the scripted run does anything -------------------

  @override
  Future<Result<String?, AppFailure>> triggerBuild(
    String jobUrl, {
    required bool isParameterized,
    Map<String, String> parameters = const {},
    Map<String, ParameterFile> files = const {},
    String? paramToken,
  }) async {
    if (jobUrl != _mainUrl) return const Err(DemoUnavailableFailure());
    final running = _script;
    if (running != null && !running.isDone(_now)) {
      return Ok(running.queueUrl);
    }
    final latest = _builds[_mainUrl]!.first.number;
    final script = DemoBuildScript((running?.number ?? latest) + 1, _now);
    _script = script;
    return Ok(script.queueUrl);
  }

  @override
  Future<Result<void, AppFailure>> scanMultibranch(String projectUrl) async =>
      _unavailable;

  @override
  Future<Result<void, AppFailure>> setJobEnabled(
    String jobUrl, {
    required bool enabled,
  }) async => _unavailable;

  @override
  Future<Result<void, AppFailure>> toggleKeepLog(String buildUrl) async =>
      _unavailable;

  @override
  Future<Result<void, AppFailure>> setBuildDescription(
    String buildUrl,
    String description,
  ) async => _unavailable;

  @override
  Future<Result<void, AppFailure>> cancelBuild(String buildUrl) async =>
      _unavailable;

  @override
  Future<Result<void, AppFailure>> toggleNodeOffline(
    JenkinsNode node, {
    String message = '',
  }) async => _unavailable;

  @override
  Future<Result<void, AppFailure>> cancelQueueItem(int id) async =>
      _unavailable;

  @override
  Future<Result<void, AppFailure>> submitInput({
    required String buildUrl,
    required String inputId,
    required bool proceed,
    Map<String, String> parameters = const {},
  }) async => _unavailable;
}

/// One instance per demo session: leaving demo mode disposes it, and with it
/// the scripted run, so the next demo starts from the sample data again.
@riverpod
DemoJenkinsRepository demoJenkinsRepository(Ref ref) {
  // Rebuilt (and so reset) whenever demo mode flips.
  ref.watch(demoModeNotifierProvider);
  return DemoJenkinsRepository();
}
