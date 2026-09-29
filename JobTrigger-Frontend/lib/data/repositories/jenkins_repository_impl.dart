import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/guard.dart';
import '../../core/error/result.dart';
import '../../core/network/jenkins_client_factory.dart';
import '../../domain/jenkins/jenkins_build.dart';
import '../../domain/jenkins/jenkins_job.dart';
import '../../domain/jenkins/jenkins_repository.dart';
import '../../domain/jenkins/log_chunk.dart';
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

/// Fields requested at every level of the recursive tree query — ported
/// exactly from `JenkinsAPIService.fetchJobs` (Swift). Deliberately lean
/// (no healthReport/property/builds[]) — those come from the richer
/// per-job detail query in Phase 5, not this top-level fetch.
const _treeFields =
    'name,url,color,description,lastBuild[number,url,result,building,estimatedDuration,timestamp]';

/// Builds the depth-limited (6 levels) `tree` query param — see
/// `docs/api-reference.md`'s "Recursive job/folder tree" row.
String buildJobTreeQuery() {
  var nested = _treeFields;
  for (var i = 0; i < 4; i++) {
    nested = '$_treeFields,jobs[$nested]';
  }
  return 'jobs[$nested]';
}

/// Richer per-job fields — params, health, last build — ported exactly from
/// `JenkinsAPIService.fetchJobDetails`'s `detailsTree` (Swift).
const _detailsTree =
    'name,url,color,description,'
    'lastBuild[number,url,result,timestamp,duration,building,estimatedDuration,'
    'actions[causes[shortDescription,upstreamProject,upstreamUrl]],'
    'changeSet[items[msg,author[fullName]]],'
    'artifacts[fileName,relativePath]],'
    'healthReport[description,iconClassName,score],'
    'property[parameterDefinitions[name,type,description,defaultParameterValue[value],choices]],'
    'downstreamProjects[name,url]';

/// US-PIPE-06 — counts plus enough of each case to identify a failing one.
const _testReportTree =
    'passCount,failCount,skipCount,suites[cases[className,name,status]]';

/// Last 20 builds — ported exactly from
/// `JenkinsAPIService.fetchBuildHistory`'s `historyTree` (Swift), plus
/// `actions[parameters[name,value]]` (US-PIPE-08 — a build's actually-used
/// parameter values, for "replay with same parameters").
const _historyTree =
    'builds[number,url,result,timestamp,duration,displayName,building,'
    'estimatedDuration,actions[parameters[name,value]]]{0,20}';

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
  Future<Result<List<JenkinsBuild>, AppFailure>> fetchJobHistory(
    String jobUrl,
  ) => guardRequest(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${_withSlash(jobUrl)}api/json',
      queryParameters: {'tree': _historyTree},
    );
    final buildsJson = response.data?['builds'] as List<dynamic>? ?? const [];
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
    String? paramToken,
  }) => guardRequest(() async {
    final hasParams = parameters.isNotEmpty;
    final action = (isParameterized || hasParams)
        ? 'buildWithParameters'
        : 'build';
    final response = await _dio.post<void>(
      '${_withSlash(jobUrl)}$action',
      data: hasParams ? parameters : null,
      queryParameters: (paramToken != null && paramToken.isNotEmpty)
          ? {'token': paramToken}
          : null,
      options: Options(
        contentType: hasParams ? Headers.formUrlEncodedContentType : null,
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
  /// read-only user (P11-02). Mapped to [AuthFailure] so it reads as a
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
      return const Err(AuthFailure());
    }
    return null;
  }
}

@riverpod
JenkinsRepository jenkinsRepository(Ref ref) =>
    JenkinsRepositoryImpl(ref.watch(jenkinsClientProvider));
