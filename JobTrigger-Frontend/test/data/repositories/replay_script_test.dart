import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/data/repositories/replay_script_parser.dart';
import 'package:job_trigger/domain/jenkins/replay_script.dart';

// US-JX-16 AC2, AC3, AC5, AC7: the script source and the submit contract.

const _inlineConfig = '''<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@1400">
  <description></description>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps@4000">
    <script>pipeline {
  agent any
  stages { stage(&apos;Build&apos;) { steps { sh &quot;make &amp;&amp; echo &lt;ok&gt;&quot; } } }
}&#13;</script>
    <sandbox>true</sandbox>
  </definition>
</flow-definition>''';

const _scmConfig = '''<flow-definition>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@4000">
    <scriptPath>Jenkinsfile</scriptPath>
  </definition>
</flow-definition>''';

class _Request {
  _Request(this.options, this.body);
  final RequestOptions options;
  final String body;
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, [this.body = '']);
  final int status;
  final String body;
  final requests = <_Request>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = requestStream == null
        ? <int>[]
        : (await requestStream.toList()).expand((chunk) => chunk).toList();
    requests.add(_Request(options, utf8.decode(bytes)));
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: ['application/xml'],
        if (status == 302) 'location': ['https://ci.test/job/deploy/'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

JenkinsRepositoryImpl _repo(_Adapter adapter) => JenkinsRepositoryImpl(
  Dio(BaseOptions(baseUrl: 'https://ci.test'))..httpClientAdapter = adapter,
);

void main() {
  group('parseReplayScript', () {
    test('reads an inline script and decodes XML entities (AC2)', () {
      final script = parseReplayScript(_inlineConfig) as InlineReplayScript;
      expect(script.sandbox, isTrue);
      expect(script.script, startsWith('pipeline {\n  agent any'));
      expect(script.script, contains("stage('Build')"));
      expect(script.script, contains('sh "make && echo <ok>"'));
      expect(script.script, endsWith('}\r'));
    });

    test('recognises a Jenkinsfile from SCM (AC3)', () {
      expect(parseReplayScript(_scmConfig), isA<ScmReplayScript>());
    });

    test('a job without a pipeline definition has no script', () {
      expect(
        parseReplayScript('<project><builders/></project>'),
        isA<NoReplayScript>(),
      );
      expect(
        parseReplayScript(
          '<flow-definition><definition class="x.Other"></definition></flow-definition>',
        ),
        isA<NoReplayScript>(),
      );
    });

    test('sandbox off is kept', () {
      final xml = _inlineConfig.replaceFirst(
        '<sandbox>true</sandbox>',
        '<sandbox>false</sandbox>',
      );
      expect((parseReplayScript(xml) as InlineReplayScript).sandbox, isFalse);
    });
  });

  group('JenkinsRepositoryImpl', () {
    test('fetchReplayScript GETs the job config.xml (AC2)', () async {
      final adapter = _Adapter(200, _inlineConfig);
      final result = await _repo(
        adapter,
      ).fetchReplayScript('https://ci.test/job/deploy');

      expect(adapter.requests.single.options.method, 'GET');
      expect(
        adapter.requests.single.options.uri.path,
        '/job/deploy/config.xml',
      );
      expect(
        (result as Ok<ReplayScript, AppFailure>).value,
        isA<InlineReplayScript>(),
      );
    });

    test('a 403 on config.xml is a PermissionFailure (AC5)', () async {
      final result = await _repo(
        _Adapter(403),
      ).fetchReplayScript('https://ci.test/job/deploy/');
      expect(
        (result as Err<ReplayScript, AppFailure>).error,
        isA<PermissionFailure>(),
      );
    });

    test(
      'replayWithScript posts the form contract and accepts 302 (AC7)',
      () async {
        final adapter = _Adapter(302);
        const script = 'echo "a & b"';
        final result = await _repo(
          adapter,
        ).replayWithScript('https://ci.test/job/deploy/41/', script);

        expect(result, isA<Ok<void, AppFailure>>());
        final request = adapter.requests.single;
        expect(request.options.method, 'POST');
        expect(request.options.uri.path, '/job/deploy/41/replay/run');
        expect(request.options.contentType, Headers.formUrlEncodedContentType);
        final form = Uri.splitQueryString(request.body);
        expect(form['_.mainScript'], script);
        expect(jsonDecode(form['json']!), {'mainScript': script});
      },
    );

    test('a 403 or 404 on submit is a failure, not a crash (AC5)', () async {
      for (final status in [403, 404]) {
        final result = await _repo(
          _Adapter(status),
        ).replayWithScript('https://ci.test/job/deploy/41/', 'x');
        expect(result, isA<Err<void, AppFailure>>(), reason: '$status');
      }
    });
  });

  test('wasReplayed reads the cause Jenkins writes (AC4)', () {
    expect(wasReplayed(['Started by user admin']), isFalse);
    expect(wasReplayed(['Replayed #40', 'Started by user admin']), isTrue);
    expect(replayedCause(41), 'Replayed #41');
  });
}
