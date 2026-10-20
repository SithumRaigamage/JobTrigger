import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/platform/temp_files.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/build_artifact.dart';
import 'package:job_trigger/presentation/common_widgets/toast_controller.dart';
import 'package:job_trigger/presentation/features/job_detail/artifact_download_notifier.dart';

import '../../../support/fake_jenkins_repository.dart';

const _buildUrl = 'https://jenkins.test/job/demo/1/';
const _artifact = BuildArtifact(
  fileName: 'app.apk',
  relativePath: 'build/outputs/app.apk',
);

class _FakeRepository extends FakeJenkinsRepository {
  _FakeRepository({this.size = const Ok(1024), this.download = const Ok(null)});

  final Result<int?, AppFailure> size;
  final Result<void, AppFailure> download;
  int downloads = 0;

  @override
  Future<Result<int?, AppFailure>> fetchArtifactSize(
    String buildUrl,
    String relativePath,
  ) async => size;

  @override
  Future<Result<void, AppFailure>> downloadArtifact(
    String buildUrl,
    String relativePath,
    String savePath, {
    void Function(int received, int? total)? onProgress,
  }) async {
    downloads++;
    if (download is Ok) {
      File(savePath).writeAsBytesSync([1, 2, 3]);
      onProgress?.call(3, 3);
    }
    return download;
  }
}

void main() {
  late Directory directory;
  late List<String> shared;
  late bool fileExistedWhenShared;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('jt-artifacts');
    shared = [];
    fileExistedWhenShared = false;
  });
  tearDown(() => directory.deleteSync(recursive: true));

  final provider = artifactDownloadNotifierProvider(
    _buildUrl,
    _artifact.relativePath,
  );

  ProviderContainer container(_FakeRepository repo) {
    final c = ProviderContainer(
      overrides: [
        jenkinsRepositoryProvider.overrideWithValue(repo),
        tempDirectoryProvider.overrideWith((ref) async => directory),
        fileSharerProvider.overrideWithValue((path, subject) async {
          fileExistedWhenShared = File(path).existsSync();
          shared.add(subject);
        }),
      ],
    );
    addTearDown(c.dispose);
    // autoDispose: keep it alive through the async download.
    c
      ..listen(provider, (_, _) {})
      ..listen(currentToastProvider, (_, _) {});
    return c;
  }

  test('streams to a temp file, shares it, then deletes it (AUD-21)', () async {
    final repo = _FakeRepository();
    final c = container(repo);

    final largeSize = await c.read(provider.notifier).download(_artifact);

    expect(largeSize, isNull);
    expect(repo.downloads, 1);
    expect(shared, ['app.apk']);
    expect(fileExistedWhenShared, isTrue);
    expect(directory.listSync(), isEmpty); // Nothing kept.
    expect(c.read(provider).value, isNull); // Idle again.
  });

  test('a large artifact waits for confirmation', () async {
    const bytes = ArtifactDownloadNotifier.largeBytes + 1;
    final repo = _FakeRepository(size: const Ok(bytes));
    final c = container(repo);
    final notifier = c.read(provider.notifier);

    expect(await notifier.download(_artifact), bytes);
    expect(repo.downloads, 0);
    expect(c.read(provider).value, isNull);

    expect(await notifier.download(_artifact, allowLarge: true), isNull);
    expect(repo.downloads, 1);
  });

  test('an unknown or unreadable size still downloads', () async {
    final repo = _FakeRepository(size: const Err(ServerFailure(405)));
    final c = container(repo);
    await c.read(provider.notifier).download(_artifact);
    expect(repo.downloads, 1);
  });

  test(
    'a failed download is an error with a toast, and leaves no file',
    () async {
      final repo = _FakeRepository(download: const Err(NetworkFailure()));
      final c = container(repo);

      await c.read(provider.notifier).download(_artifact);

      expect(c.read(provider).error, isA<NetworkFailure>());
      expect(c.read(currentToastProvider)?.type, ToastType.error);
      expect(shared, isEmpty);
      expect(directory.listSync(), isEmpty);
    },
  );

  test('the same path in another build has its own state (AUD-29)', () async {
    final repo = _FakeRepository(download: const Err(NetworkFailure()));
    final c = container(repo);
    final other = artifactDownloadNotifierProvider(
      'https://jenkins.test/job/demo/2/',
      _artifact.relativePath,
    );
    c.listen(other, (_, _) {});

    await c.read(provider.notifier).download(_artifact);

    expect(c.read(provider).hasError, isTrue);
    expect(c.read(other).hasError, isFalse);
  });
}
