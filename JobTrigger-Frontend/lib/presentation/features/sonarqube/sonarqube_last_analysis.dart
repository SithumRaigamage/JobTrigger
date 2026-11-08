import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/sonarqube_repository_impl.dart';
import '../../../domain/jenkins/relative_time.dart';
import '../../../domain/sonarqube/sonarqube_project.dart';

part 'sonarqube_last_analysis.g.dart';

/// When a project was last analysed, from its analysis history: the newest
/// analysis, or null if it has never been analysed.
///
/// The project list normally carries this date, but a server may leave it
/// out; a project is only called "never analysed" when its history is
/// really empty, not when the list was silent.
@riverpod
Future<DateTime?> sonarQubeLastAnalysis(Ref ref, String projectKey) async {
  final result = await ref
      .watch(sonarQubeRepositoryProvider)
      .fetchAnalysisHistory(projectKey);
  final analyses = result.fold(
    (analyses) => analyses,
    (failure) => throw failure,
  );
  for (final analysis in analyses) {
    if (analysis.date != null) return analysis.date; // newest first
  }
  return null;
}

/// "Analyzed 3h ago", using the list's date when it has one and otherwise
/// asking for the project's latest analysis.
class LastAnalysisText extends ConsumerWidget {
  const LastAnalysisText({
    required this.project,
    this.style,
    this.prefix = 'Analyzed',
    super.key,
  });

  final SonarQubeProject project;
  final TextStyle? style;

  /// Word ahead of the age: "Analyzed 3h ago".
  final String prefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final known = project.lastAnalysisDate;
    if (known != null) {
      return Text('$prefix ${relativeTime(known)}', style: style);
    }
    final lookup = ref.watch(sonarQubeLastAnalysisProvider(project.key));
    return Text(
      lookup.when(
        data: (date) =>
            date == null ? 'Never analyzed' : '$prefix ${relativeTime(date)}',
        loading: () => 'Checking last analysis…',
        error: (_, _) => 'Last analysis unknown',
      ),
      style: style,
    );
  }
}
