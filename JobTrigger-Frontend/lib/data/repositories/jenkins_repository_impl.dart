import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/guard.dart';
import '../../core/error/result.dart';
import '../../core/network/jenkins_client_factory.dart';
import '../../domain/jenkins/branch_kind.dart';
import '../../domain/jenkins/history_filter.dart';
import '../../domain/jenkins/jenkins_build.dart';
import '../../domain/jenkins/jenkins_job.dart';
import '../../domain/jenkins/jenkins_repository.dart';
import '../../domain/jenkins/log_chunk.dart';
import '../../domain/jenkins/parameter_file.dart';
import '../../domain/jenkins/pending_input.dart';
import '../../domain/jenkins/pipeline_stage.dart';
import '../../domain/jenkins/queue_item.dart';
import '../../domain/jenkins/test_report.dart';
import '../models/jenkins/jenkins_build_dto.dart';
import '../models/jenkins/jenkins_job_dto.dart';
import '../models/jenkins/jenkins_server_info_dto.dart';
import '../models/jenkins/pending_input_dto.dart';
import '../models/jenkins/pipeline_stage_dto.dart';
import '../models/jenkins/queue_item_dto.dart';
import '../models/jenkins/test_report_dto.dart';
import 'jenkins_url_rewriter.dart';

part 'jenkins_repository_impl.g.dart';

/// Fields requested for each job in a tree or folder listing — ported from
/// `JenkinsAPIService.fetchJobs` (Swift), plus `_class`, `displayName`, and
/// `buildable` (P11-05). Deliberately lean (no healthReport/property/
/// builds[]) — those come from the per-job detail query.
const _treeFields =
    '_class,name,displayName,url,color,description,buildable,'
    'lastBuild[number,url,result,building,estimatedDuration,timestamp]';

/// How many folder levels the recursive crawl (search and global history)
/// reaches. Browsing isn't limited by this: Home loads folders lazily via
/// [JenkinsRepositoryImpl.fetchFolder] (AUD-19/20).
const jobTreeCrawlDepth = 6;

/// Builds the depth-limited `tree` query param for the recursive crawl —
/// see `docs/api-reference.md`'s "Recursive job/folder tree" row. Previously
/// built 5 levels while documenting 6 (AUD-19).
String buildJobTreeQuery() {
  var nested = _treeFields;
  for (var level = 1; level < jobTreeCrawlDepth; level++) {
    nested = '$_treeFields,jobs[$nested]';
  }
  return 'jobs[$nested]';
}

/// Richer per-job fields — params, health, last build — ported exactly from
/// `JenkinsAPIService.fetchJobDetails`'s `detailsTree` (Swift).
const _detailsTree =
    '_class,name,displayName,url,color,description,buildable,'
    'lastBuild[number,url,result,timestamp,duration,building,estimatedDuration,'
    'actions[causes[shortDescription,upstreamProject,upstreamUrl]],'
    'changeSet[items[msg,author[fullName]]],'
    'artifacts[fileName,relativePath]],'
    'healthReport[description,iconClassName,score],'
    'property[parameterDefinitions[name,type,description,defaultParameterValue[value],choices,projectName]],'
    'downstreamProjects[name,url],'
    // US-JX-05: quick links to the last good and last broken build.
    'lastSuccessfulBuild[number,url,result,timestamp],'
    'lastFailedBuild[number,url,result,timestamp]';

/// US-PIPE-06 — counts plus enough of each case to identify a failing one.
const _testReportTree =
    'passCount,failCount,skipCount,suites[cases[className,name,status]]';

/// One page of history — ported from `JenkinsAPIService.fetchBuildHistory`'s
/// `historyTree` (Swift), plus `actions[parameters[name,value]]` (US-PIPE-08
/// replay) and `causes[userId]` (US-JX-06 "started by me"). Uses
/// `allBuilds{from,to}` rather than `builds`, which Jenkins caps at 100, so
/// paging reaches all of history (verified on the fixture; past the end is
/// an empty list).
String _historyTree(int from, int to) =>
    'allBuilds[number,url,result,timestamp,duration,displayName,building,'
    'estimatedDuration,actions[parameters[name,value],causes[userId]]]'
    '{$from,$to}';

/// Jenkins resource URLs are directories; every sub-path (`api/json`,
/// `build`, `stop`, …) is appended to a trailing-slash form (AUD-32).
String _withSlash(String url) => url.endsWith('/') ? url : '$url/';

/// "No such resource" is a normal, non-error state for optional per-build
/// data (no test report, not a pipeline, nothing paused) — surfaced by
/// Jenkins as a real 404.
Result<T?, AppFailure>? _notFoundAsNull<T>(DioException exception) =>
    exception.response?.statusCode == 404 ? const Ok(null) : null;

class JenkinsRepositoryImpl implements JenkinsRepository {
  JenkinsRepositoryImpl(this._dio);

  final Dio _dio;

  String get _baseUrl => _dio.options.baseUrl;

  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchJobTree() =>
      guardRequest(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/api/json',
          queryParameters: {'tree': buildJobTreeQuery()},
        );
        final serverInfo = JenkinsServerInfoDto.fromJson(response.data!);
        final jobs = serverInfo.jobs.map((dto) => dto.toDomain()).toList();
        return rewriteJobTreeUrls(jobs, _baseUrl);
      });

  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchFolder(String? folderUrl) =>
      guardRequest(() async {
        final path = folderUrl == null
            ? '/api/json'
            : '${_withSlash(folderUrl)}api/json';
        final response = await _dio.get<Map<String, dynamic>>(
          path,
          queryParameters: {'tree': 'jobs[$_treeFields]'},
        );
        final jobsJson = response.data?['jobs'] as List<dynamic>? ?? const [];
        final jobs = jobsJson
            .map(
              (json) => JenkinsJobDto.fromJson(
                json as Map<String, dynamic>,
              ).toDomain(),
            )
            .toList();
        return rewriteJobTreeUrls(jobs, _baseUrl);
      });

  @override
  Future<Result<Map<String, BranchKind>, AppFailure>> fetchBranchKinds(
    String multibranchUrl,
  ) => guardRequest(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${_withSlash(multibranchUrl)}api/json',
      queryParameters: {'tree': 'views[name,jobs[name]]'},
    );
    final views = response.data?['views'] as List<dynamic>? ?? const [];
    return branchKindsFromViews({
      for (final view in views.cast<Map<String, dynamic>>())
        view['name'] as String: [
          for (final job
              in (view['jobs'] as List<dynamic>? ?? const [])
                  .cast<Map<String, dynamic>>())
            job['name'] as String,
        ],
    });
  });

  @override
  Future<Result<void, AppFailure>> scanMultibranch(String projectUrl) =>
      guardRequest(
        () => _dio.post<void>(
          '${_withSlash(projectUrl)}build',
          queryParameters: {'delay': 0},
          // Jenkins redirects (302) back to the project after queueing the
          // scan; Dart doesn't follow redirects for POST.
          options: Options(
            followRedirects: false,
            validateStatus: (status) => status != null && status < 400,
          ),
        ),
      );

  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobDetail(String jobUrl) =>
      guardRequest(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '${_withSlash(jobUrl)}api/json',
          queryParameters: {'tree': _detailsTree},
        );
        final job = JenkinsJobDto.fromJson(response.data!).toDomain();
        return rewriteJobTreeUrls([job], _baseUrl).single;
      });

  @override
  Future<Result<LogChunk, AppFailure>> streamBuildLog(
    String buildUrl, {
    int start = 0,
  }) => guardRequest(() async {
    final response = await _dio.get<String>(
      '${_withSlash(buildUrl)}logText/progressiveText',
      queryParameters: {'start': start},
      options: Options(responseType: ResponseType.plain),
    );
    final text = response.data ?? '';
    final nextOffsetHeader = response.headers.value('X-Text-Size');
    final hasMoreHeader = response.headers.value('X-More-Data');
    return LogChunk(
      text: text,
      nextOffset: int.tryParse(nextOffsetHeader ?? '') ?? (start + text.length),
      hasMoreData: hasMoreHeader?.toLowerCase() == 'true',
    );
  });

  @override
  Future<Result<int, AppFailure>> fetchLogSize(String buildUrl) =>
      guardRequest(() async {
        final response = await _dio.head<void>(
          '${_withSlash(buildUrl)}logText/progressiveText',
          queryParameters: {'start': 0},
        );
        return int.parse(response.headers.value('X-Text-Size') ?? '0');
      });

  @override
  Future<Result<List<String>?, AppFailure>> fetchTimestamps(
    String buildUrl, {
    required int startLine,
    int? endLine,
  }) => guardRequest(() async {
    final response = await _dio.get<String>(
      '${_withSlash(buildUrl)}timestamps/',
      queryParameters: {
        'time': 'HH:mm:ss',
        'startLine': startLine,
        'endLine': ?endLine,
      },
      options: Options(responseType: ResponseType.plain),
    );
    final body = response.data ?? '';
    if (body.isEmpty) return const <String>[];
    final lines = body.split('\n');
    // The body ends with a newline; that's not an extra empty line.
    if (lines.last.isEmpty) lines.removeLast();
    return lines;
  }, recover: _notFoundAsNull);

  @override
  Future<Result<void, AppFailure>> downloadConsoleText(
    String buildUrl,
    String savePath,
  ) => guardRequest(
    () => _dio.download(
      '${_withSlash(buildUrl)}consoleText',
      savePath,
      // A full log can be tens of MB; don't apply the 15s API timeout.
      options: Options(receiveTimeout: const Duration(minutes: 5)),
    ),
  );

  @override
  Future<Result<List<JenkinsBuild>, AppFailure>> fetchJobHistory(
    String jobUrl, {
    int start = 0,
    int count = historyPageSize,
  }) => guardRequest(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${_withSlash(jobUrl)}api/json',
      queryParameters: {'tree': _historyTree(start, start + count)},
    );
    final buildsJson =
        response.data?['allBuilds'] as List<dynamic>? ?? const [];
    final builds = buildsJson
        .map(
          (json) =>
              JenkinsBuildDto.fromJson(json as Map<String, dynamic>).toDomain(),
        )
        .toList();
    return rewriteBuildUrls(builds, _baseUrl);
  });

  @override
  Future<Result<String?, AppFailure>> triggerBuild(
    String jobUrl, {
    required bool isParameterized,
    Map<String, String> parameters = const {},
    Map<String, ParameterFile> files = const {},
    String? paramToken,
  }) => guardRequest(() async {
    final hasParams = parameters.isNotEmpty || files.isNotEmpty;
    final action = (isParameterized || hasParams)
        ? 'buildWithParameters'
        : 'build';
    final Object? body;
    final String? contentType;
    if (files.isNotEmpty) {
      body = FormData.fromMap({
        ...parameters,
        for (final MapEntry(key: name, value: file) in files.entries)
          name: await MultipartFile.fromFile(
            file.path,
            filename: file.fileName,
          ),
      });
      contentType = null; // Dio sets the multipart boundary itself.
    } else {
      body = parameters.isEmpty ? null : parameters;
      contentType = parameters.isEmpty
          ? null
          : Headers.formUrlEncodedContentType;
    }
    final response = await _dio.post<void>(
      '${_withSlash(jobUrl)}$action',
      data: body,
      queryParameters: (paramToken != null && paramToken.isNotEmpty)
          ? {'token': paramToken}
          : null,
      options: Options(
        contentType: contentType,
        // AUD-37: when an identical parameterized build is already queued,
        // Jenkins merges the request into it and answers `303 See Other`
        // with that queue item as `Location`. That's an accepted trigger,
        // but Dart doesn't follow redirects for POST, so without this Dio
        // reported it as a failure. Verified on the fixture Jenkins.
        followRedirects: false,
        validateStatus: (status) => status != null && status < 400,
      ),
    );
    final location = response.headers.value('location');
    return location == null ? null : rewriteUrl(location, _baseUrl);
  });

  @override
  Future<Result<void, AppFailure>> cancelBuild(String buildUrl) =>
      guardRequest(() => _dio.post<void>('${_withSlash(buildUrl)}stop'));

  @override
  Future<Result<QueueItem, AppFailure>> fetchQueueItem(String queueItemUrl) =>
      guardRequest(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '${_withSlash(queueItemUrl)}api/json',
        );
        final item = QueueItemDto.fromJson(response.data!).toDomain();
        return rewriteQueueItemUrl(item, _baseUrl);
      });

  @override
  Future<Result<TestReport?, AppFailure>> fetchTestReport(String buildUrl) =>
      guardRequest(
        () async {
          final response = await _dio.get<Map<String, dynamic>>(
            '${_withSlash(buildUrl)}testReport/api/json',
            queryParameters: {'tree': _testReportTree},
          );
          return TestReportDto.fromJson(response.data!).toDomain();
        },
        // No published test report (US-PIPE-06).
        recover: _notFoundAsNull,
      );

  @override
  Future<Result<Uint8List, AppFailure>> fetchArtifactBytes(
    String buildUrl,
    String relativePath,
  ) => guardRequest(() async {
    // Each path segment is percent-encoded separately so `/` in a
    // subdirectory-relative path stays a path separator rather than
    // being encoded away.
    final encodedPath = relativePath
        .split('/')
        .map(Uri.encodeComponent)
        .join('/');
    final response = await _dio.get<List<int>>(
      '${_withSlash(buildUrl)}artifact/$encodedPath',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  });

  @override
  Future<Result<List<PipelineStage>?, AppFailure>> fetchPipelineStages(
    String buildUrl,
  ) => guardRequest(
    () async {
      final response = await _dio.get<Map<String, dynamic>>(
        '${_withSlash(buildUrl)}wfapi/describe',
      );
      return PipelineDescribeDto.fromJson(response.data!).toDomain();
    },
    // Freestyle job, or no Pipeline: REST API plugin (US-PIPE-04).
    recover: _notFoundAsNull,
  );

  @override
  Future<Result<List<PipelineStep>?, AppFailure>> fetchStageSteps(
    String buildUrl,
    String stageId,
  ) => guardRequest(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${_withSlash(buildUrl)}execution/node/'
      '${Uri.encodeComponent(stageId)}/wfapi/describe',
    );
    return PipelineStageDto.fromJson(response.data!).stepsToDomain();
  }, recover: _notFoundAsNull);

  @override
  Future<Result<StepLog, AppFailure>> fetchStepLog(
    String buildUrl,
    String stepId,
  ) => guardRequest(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${_withSlash(buildUrl)}execution/node/'
      '${Uri.encodeComponent(stepId)}/wfapi/log',
    );
    return StepLogDto.fromJson(response.data!).toDomain();
  });

  @override
  Future<Result<PendingInput?, AppFailure>> fetchPendingInput(
    String buildUrl,
  ) => guardRequest(
    () async {
      final response = await _dio.get<List<dynamic>>(
        '${_withSlash(buildUrl)}wfapi/pendingInputActions',
      );
      final list = response.data ?? const [];
      if (list.isEmpty) return null;
      return PendingInputDto.fromJson(
        list.first as Map<String, dynamic>,
      ).toDomain();
    },
    // No Pipeline: REST API plugin, or an older Jenkins that 404s instead
    // of returning an empty array when nothing is paused.
    recover: _notFoundAsNull,
  );

  @override
  Future<Result<void, AppFailure>> submitInput({
    required String buildUrl,
    required String inputId,
    required bool proceed,
    Map<String, String> parameters = const {},
  }) => guardRequest(() async {
    final inputBase =
        '${_withSlash(buildUrl)}input/${Uri.encodeComponent(inputId)}/';
    // Plain text, so a rejection's HTML body is readable in `recover`.
    final options = Options(responseType: ResponseType.plain);
    if (!proceed) {
      await _dio.post<String>('${inputBase}abort', options: options);
    } else if (parameters.isEmpty) {
      await _dio.post<String>('${inputBase}proceedEmpty', options: options);
    } else {
      // Verified on a real server (P11-02): Jenkins reads an input step's
      // values from a Stapler `json` form field, never from plain
      // `name=value` fields (those get a 400).
      await _dio.post<String>(
        '${inputBase}proceed',
        data: {'json': jsonEncode(_staplerParameters(parameters))},
        options: options.copyWith(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
    }
  }, recover: _inputPermissionDenied);

  static Map<String, Object> _staplerParameters(
    Map<String, String> parameters,
  ) => {
    'parameter': [
      for (final MapEntry(:key, :value) in parameters.entries)
        {'name': key, 'value': value},
    ],
  };

  /// Jenkins rejects an input submission from a user without `Job/Build`
  /// with a **400** HTML error page ("You need to have Job/Build
  /// permissions to submit this."), not a 403 — verified on the fixture's
  /// read-only user (P11-02). Mapped to [PermissionFailure] so it reads as a
  /// permission problem, not a server error. The app sends no
  /// `Accept-Language`, so Jenkins answers in its default (English) locale.
  static Result<void, AppFailure>? _inputPermissionDenied(
    DioException exception,
  ) {
    final response = exception.response;
    final body = response?.data;
    if (response?.statusCode == 400 &&
        body is String &&
        body.contains('permission')) {
      return const Err(PermissionFailure());
    }
    return null;
  }
}

@riverpod
JenkinsRepository jenkinsRepository(Ref ref) =>
    JenkinsRepositoryImpl(ref.watch(jenkinsClientProvider));
