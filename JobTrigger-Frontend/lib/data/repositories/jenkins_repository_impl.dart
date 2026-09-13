import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import '../../core/network/jenkins_client_factory.dart';
import '../../domain/jenkins/jenkins_build.dart';
import '../../domain/jenkins/jenkins_job.dart';
import '../../domain/jenkins/jenkins_repository.dart';
import '../../domain/jenkins/log_chunk.dart';
import '../models/jenkins/jenkins_build_dto.dart';
import '../models/jenkins/jenkins_job_dto.dart';
import '../models/jenkins/jenkins_server_info_dto.dart';
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
    'lastBuild[number,url,result,timestamp,duration,building,estimatedDuration],'
    'healthReport[description,iconClassName,score],'
    'property[parameterDefinitions[name,type,description,defaultParameterValue[value],choices]]';

/// Last 20 builds — ported exactly from
/// `JenkinsAPIService.fetchBuildHistory`'s `historyTree` (Swift).
const _historyTree =
    'builds[number,url,result,timestamp,duration,displayName,building,estimatedDuration]{0,20}';

class JenkinsRepositoryImpl implements JenkinsRepository {
  JenkinsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchJobTree() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/json',
        queryParameters: {'tree': buildJobTreeQuery()},
      );
      final serverInfo = JenkinsServerInfoDto.fromJson(response.data!);
      final jobs = serverInfo.jobs.map((dto) => dto.toDomain()).toList();
      return Ok(rewriteJobTreeUrls(jobs, _dio.options.baseUrl));
    } on DioException catch (exception) {
      return Err(AppFailure.fromDioException(exception));
    }
  }

  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobDetail(String jobUrl) async {
    try {
      final base = jobUrl.endsWith('/') ? jobUrl : '$jobUrl/';
      final response = await _dio.get<Map<String, dynamic>>(
        '${base}api/json',
        queryParameters: {'tree': _detailsTree},
      );
      final job = JenkinsJobDto.fromJson(response.data!).toDomain();
      return Ok(rewriteJobTreeUrls([job], _dio.options.baseUrl).single);
    } on DioException catch (exception) {
      return Err(AppFailure.fromDioException(exception));
    }
  }

  @override
  Future<Result<LogChunk, AppFailure>> streamBuildLog(
    String buildUrl, {
    int start = 0,
  }) async {
    try {
      final base = buildUrl.endsWith('/') ? buildUrl : '$buildUrl/';
      final response = await _dio.get<String>(
        '${base}logText/progressiveText',
        queryParameters: {'start': start},
        options: Options(responseType: ResponseType.plain),
      );
      final text = response.data ?? '';
      final nextOffsetHeader = response.headers.value('X-Text-Size');
      final hasMoreHeader = response.headers.value('X-More-Data');
      return Ok(
        LogChunk(
          text: text,
          nextOffset:
              int.tryParse(nextOffsetHeader ?? '') ?? (start + text.length),
          hasMoreData: hasMoreHeader?.toLowerCase() == 'true',
        ),
      );
    } on DioException catch (exception) {
      return Err(AppFailure.fromDioException(exception));
    }
  }

  @override
  Future<Result<List<JenkinsBuild>, AppFailure>> fetchJobHistory(
    String jobUrl,
  ) async {
    try {
      final base = jobUrl.endsWith('/') ? jobUrl : '$jobUrl/';
      final response = await _dio.get<Map<String, dynamic>>(
        '${base}api/json',
        queryParameters: {'tree': _historyTree},
      );
      final buildsJson = response.data?['builds'] as List<dynamic>? ?? const [];
      final builds = buildsJson
          .map(
            (json) => JenkinsBuildDto.fromJson(
              json as Map<String, dynamic>,
            ).toDomain(),
          )
          .toList();
      return Ok(rewriteBuildUrls(builds, _dio.options.baseUrl));
    } on DioException catch (exception) {
      return Err(AppFailure.fromDioException(exception));
    }
  }

  @override
  Future<Result<void, AppFailure>> triggerBuild(
    String jobUrl, {
    required bool isParameterized,
    Map<String, String> parameters = const {},
    String? paramToken,
  }) async {
    try {
      final base = jobUrl.endsWith('/') ? jobUrl : '$jobUrl/';
      final hasParams = parameters.isNotEmpty;
      final action = (isParameterized || hasParams)
          ? 'buildWithParameters'
          : 'build';
      await _dio.post<void>(
        '$base$action',
        data: hasParams ? parameters : null,
        queryParameters: (paramToken != null && paramToken.isNotEmpty)
            ? {'token': paramToken}
            : null,
        options: hasParams
            ? Options(contentType: Headers.formUrlEncodedContentType)
            : null,
      );
      return const Ok(null);
    } on DioException catch (exception) {
      return Err(AppFailure.fromDioException(exception));
    }
  }

  @override
  Future<Result<void, AppFailure>> cancelBuild(String buildUrl) async {
    try {
      final base = buildUrl.endsWith('/') ? buildUrl : '$buildUrl/';
      await _dio.post<void>('${base}stop');
      return const Ok(null);
    } on DioException catch (exception) {
      return Err(AppFailure.fromDioException(exception));
    }
  }
}

@riverpod
JenkinsRepository jenkinsRepository(Ref ref) =>
    JenkinsRepositoryImpl(ref.watch(jenkinsClientProvider));
