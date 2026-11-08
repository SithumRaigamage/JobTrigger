import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'sonarqube_projects_notifier.dart';
import 'sonarqube_summaries_notifier.dart';

part 'sonarqube_summaries_sync.g.dart';

/// Keeps the summaries loaded for every project in the list: watch it from a
/// screen that shows them. A side-effect-only provider, so the project list
/// and the overview share one rule instead of each wiring it up.
@riverpod
void sonarQubeSummariesSync(Ref ref) {
  // Hold the summaries notifier open while this runs. It is auto-disposed
  // and the code below only *reads* it, so without a listener it could be
  // disposed while its request is in flight and the answer thrown away.
  ref.listen(sonarQubeSummariesNotifierProvider, (_, _) {});
  ref.listen(sonarQubeProjectsNotifierProvider, (_, next) {
    final keys = next.value?.projects.map((p) => p.key).toList();
    if (keys != null) {
      ref.read(sonarQubeSummariesNotifierProvider.notifier).ensure(keys);
    }
  }, fireImmediately: true);
}
