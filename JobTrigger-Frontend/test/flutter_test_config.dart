import 'dart:async';

import 'package:job_trigger/domain/tools/tool_catalog.dart';

/// Every test file runs with an all-tools manifest, so tools a release hides
/// (SonarQube and GitHub Actions in 1.0) stay tested. Tests of the release
/// behaviour set `ToolCatalog.current` themselves and restore it.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  ToolCatalog.current = ToolCatalog.allTools;
  await testMain();
}
