import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/config/tool_catalog_loader.dart';
import 'package:job_trigger/data/repositories/github_repository_impl.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/tools/tool_catalog.dart';
import 'package:job_trigger/presentation/features/tool_selection/active_tool_notifier.dart';
import 'package:job_trigger/presentation/features/tool_selection/ci_tool.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The shipped manifest, as `config/tools.json` has it.
ToolCatalog shipped() =>
    ToolCatalog.parse(File('config/tools.json').readAsStringSync());

class _Bundle extends CachingAssetBundle {
  _Bundle(this.text);
  final String text;

  @override
  Future<ByteData> load(String key) async {
    if (key != 'config/tools.json') throw FlutterError('unexpected $key');
    return ByteData.sublistView(Uint8List.fromList(text.codeUnits));
  }
}

void main() {
  tearDown(() => ToolCatalog.current = ToolCatalog.allTools);

  group('ToolCatalog', () {
    test(
      'the shipped manifest is release 1.0: three tools, two next',
      () {
        final catalog = shipped();
        expect(catalog.release, '1.0');
        for (final id in ['jenkins', 'sonarqube', 'githubActions']) {
          expect(catalog.isReleased(id), isTrue, reason: id);
        }
        for (final id in ['gitlab', 'circleci']) {
          expect(catalog.isReleased(id), isFalse, reason: id);
        }
        expect(catalog.comingNext, ['gitlab', 'circleci']);
        expect(catalog.versionOf('sonarqube'), '1.0');
        expect(catalog.versionOf('nope'), isNull);
      },
    );

    test('later releases release more, soonest first in "coming next"', () {
      // The shipped manifest releases all three at 1.0; a staged fixture
      // keeps the release-comparison logic across 1.1 and 1.2 covered.
      ToolCatalog stagedAt(String release) => ToolCatalog(
        release: release,
        versions: const {
          'jenkins': '1.0',
          'sonarqube': '1.1',
          'githubActions': '1.2',
          'gitlab': '1.3',
          'circleci': '1.3',
        },
      );
      expect(stagedAt('1.1').isReleased('sonarqube'), isTrue);
      expect(stagedAt('1.1').comingNext, [
        'githubActions',
        'gitlab',
        'circleci',
      ]);
      expect(stagedAt('1.2').comingNext, ['gitlab', 'circleci']);
    });

    test('versions compare as numbers: 1.10 is after 1.2', () {
      expect(ToolCatalog.compareVersions('1.10', '1.2'), greaterThan(0));
      expect(ToolCatalog.compareVersions('2.0', '1.9'), greaterThan(0));
      expect(ToolCatalog.compareVersions('1.1', '1.1'), 0);
      const catalog = ToolCatalog(release: '1.2', versions: {'a': '1.10'});
      expect(catalog.isReleased('a'), isFalse);
    });

    test('an unknown id is never released; a bad manifest throws', () {
      expect(shipped().isReleased('unknown'), isFalse);
      expect(() => ToolCatalog.parse('{"tools": {}}'), throwsFormatException);
    });

    test(
      'loadToolCatalog reads the bundled asset into ToolCatalog.current',
      () async {
        await loadToolCatalog(
          _Bundle(File('config/tools.json').readAsStringSync()),
        );
        expect(ToolCatalog.current.release, '1.0');
        expect(CiTool.jenkins.isAvailable, isTrue);
        expect(CiTool.sonarqube.isAvailable, isTrue);
        expect(CiTool.githubActions.isAvailable, isTrue);
        expect(CiTool.gitlab.isAvailable, isFalse);
      },
    );

    test('a missing or malformed asset fails loudly at launch', () async {
      await expectLater(
        loadToolCatalog(_Bundle('not json')),
        throwsA(anything),
      );
    });
  });

  group('CiTool follows the manifest', () {
    test('release 1.0 offers the three built tools; '
        '"coming next" lists the rest', () {
      ToolCatalog.current = shipped();
      expect(CiTool.values.where((t) => t.isAvailable), [
        CiTool.jenkins,
        CiTool.githubActions,
        CiTool.sonarqube,
      ]);
      expect(comingNextTools, [CiTool.gitlab, CiTool.circleci]);
      expect(CiTool.jenkins.releaseVersion, '1.0');
      expect(CiTool.sonarqube.releaseVersion, '1.0');
      expect(CiTool.githubActions.releaseVersion, '1.0');
    });

    test('the all-tools test manifest offers every implemented tool', () {
      expect(CiTool.values.where((t) => t.isAvailable), [
        CiTool.jenkins,
        CiTool.githubActions,
        CiTool.sonarqube,
      ]);
      expect(comingNextTools, isEmpty);
    });

    test('a planned tool with no code can never be available or selected', () {
      // Even a manifest that releases GitLab CI and CircleCI.
      ToolCatalog.current = ToolCatalog.allTools;
      for (final tool in [CiTool.gitlab, CiTool.circleci]) {
        expect(tool.isImplemented, isFalse);
        expect(tool.isAvailable, isFalse);
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.listen(activeToolNotifierProvider, (_, _) {});
        container.read(activeToolNotifierProvider.notifier).setActiveTool(tool);
        expect(container.read(activeToolNotifierProvider), isNull);
      }
    });

    test('an unreleased tool cannot be made the active tool', () {
      ToolCatalog.current = shipped();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(activeToolNotifierProvider, (_, _) {});
      final notifier = container.read(activeToolNotifierProvider.notifier);

      notifier.setActiveTool(CiTool.gitlab);
      expect(container.read(activeToolNotifierProvider), isNull);
      notifier.setActiveTool(CiTool.sonarqube);
      expect(container.read(activeToolNotifierProvider), CiTool.sonarqube);
      notifier.setActiveTool(CiTool.jenkins);
      expect(container.read(activeToolNotifierProvider), CiTool.jenkins);
    });
  });

  group('the manifest and the app agree', () {
    /// The repository provider each implemented tool has. A tool added to
    /// IMPLEMENTED without an entry here fails the test below.
    final repositories = <String, Object>{
      'jenkins': jenkinsRepositoryProvider,
      'githubActions': gitHubRepositoryProvider,
      'sonarqube': sonarQubeRepositoryProvider,
    };

    List<String> implementedInScript() {
      final script = File('../scripts/tools-manifest.mjs').readAsStringSync();
      final match = RegExp(
        r'IMPLEMENTED\s*=\s*\[([^\]]*)\]',
      ).firstMatch(script)!;
      return RegExp(
        r'"([A-Za-z0-9]+)"',
      ).allMatches(match.group(1)!).map((m) => m.group(1)!).toList();
    }

    test(
      'IMPLEMENTED in scripts/tools-manifest.mjs claims no more than the app has',
      () {
        final claimed = implementedInScript();
        expect(claimed, isNotEmpty);
        for (final id in claimed) {
          final tool = CiTool.values
              .where((t) => t.manifestId == id)
              .firstOrNull;
          expect(tool, isNotNull, reason: '$id has no CiTool value');
          expect(
            tool!.isImplemented,
            isTrue,
            reason: '$id is not implemented in the app',
          );
          expect(
            repositories.containsKey(id),
            isTrue,
            reason: '$id has no repository',
          );
        }
      },
    );

    test('and the app implements nothing the script does not know', () {
      final claimed = implementedInScript().toSet();
      expect(
        CiTool.values
            .where((t) => t.isImplemented)
            .map((t) => t.manifestId)
            .toSet(),
        claimed,
      );
    });

    test('every tool in the manifest is a CiTool value', () {
      for (final id in shipped().versions.keys) {
        expect(
          CiTool.values.any((t) => t.manifestId == id),
          isTrue,
          reason: id,
        );
      }
    });
  });
}
