import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the dependency direction `docs/architecture.md` §2 requires:
/// presentation → notifiers → domain → data → data sources, with `core` as
/// the shared leaf.
///
/// §11 (P13-24) found `core/network/*_client_factory.dart` importing
/// `presentation/features/settings/active_*_notifier.dart`, so the shared
/// network layer depended on the layer above it. The credential state moved
/// down to `lib/data/credentials/` and the client factories down to
/// `lib/data/datasources/` to break the cycle; this test makes sure nobody
/// puts it back.
void main() {
  /// Every `import`/`export`/`part` URI in [file], resolved to a
  /// package-relative path (`lib/...`) where possible.
  List<String> importsOf(File file) {
    final source = file.readAsStringSync();
    final pattern = RegExp(
      r'''(?:import|export|part)\s+['"]([^'"]+)['"]''',
    );
    // `flutter test` runs from the package root, so the paths below are
    // already package-relative (`lib/core/network/x.dart`).
    final from = file.path.replaceAll('\\', '/');
    final directory = from.substring(0, from.lastIndexOf('/'));
    return pattern
        .allMatches(source)
        .map((match) => match.group(1)!)
        .map((uri) {
          if (uri.startsWith('package:job_trigger/')) {
            return 'lib/${uri.substring('package:job_trigger/'.length)}';
          }
          if (uri.contains(':')) return uri; // flutter, dio, ...
          return _normalize('$directory/$uri');
        })
        .toList();
  }

  List<File> dartFilesIn(String directory) => Directory(
    directory,
  ).listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList();

  group('layering', () {
    test('core never imports presentation', () {
      final offenders = <String>[];
      for (final file in dartFilesIn('lib/core')) {
        for (final uri in importsOf(file)) {
          if (uri.startsWith('lib/presentation/')) {
            offenders.add('${file.path}: $uri');
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'lib/core is the shared leaf -- it must not depend on the layer '
            'above it:\n${offenders.join('\n')}',
      );
    });

    test('data never imports presentation', () {
      final offenders = <String>[];
      for (final file in dartFilesIn('lib/data')) {
        for (final uri in importsOf(file)) {
          if (uri.startsWith('lib/presentation/')) {
            offenders.add('${file.path}: $uri');
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'the data layer sits below presentation -- it must not import it:\n'
            '${offenders.join('\n')}',
      );
    });

    test('domain imports neither presentation nor data', () {
      final offenders = <String>[];
      for (final file in dartFilesIn('lib/domain')) {
        for (final uri in importsOf(file)) {
          if (uri.startsWith('lib/presentation/') || uri.startsWith('lib/data/')) {
            offenders.add('${file.path}: $uri');
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'the domain layer is plain Dart -- it depends on neither the '
            'presentation nor the data layer:\n${offenders.join('\n')}',
      );
    });

    test('domain stays free of Flutter, Dio and code generation', () {
      final offenders = <String>[];
      for (final file in dartFilesIn('lib/domain')) {
        for (final uri in importsOf(file)) {
          if (uri.startsWith('package:flutter/') ||
              uri.startsWith('package:dio/') ||
              uri.startsWith('package:freezed')) {
            offenders.add('${file.path}: $uri');
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'the domain layer is plain Dart -- no Flutter, Dio or generated '
            'code:\n${offenders.join('\n')}',
      );
    });
  });
}

/// Collapses `a/b/../c` into `a/c`.
String _normalize(String path) {
  final parts = <String>[];
  for (final part in path.split('/')) {
    if (part == '.' || part.isEmpty) continue;
    if (part == '..') {
      if (parts.isNotEmpty) parts.removeLast();
      continue;
    }
    parts.add(part);
  }
  return parts.join('/');
}
