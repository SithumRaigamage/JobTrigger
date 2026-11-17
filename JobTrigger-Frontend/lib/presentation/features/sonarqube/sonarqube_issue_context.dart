import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/sonarqube_repository_impl.dart';
import '../../../domain/sonarqube/sonarqube_issue.dart';

part 'sonarqube_issue_context.g.dart';

/// The rule's name and the code around one issue (`US-SQ-QUALITY-06`).
/// Keyed by the issue, which is equal to another with the same key.
@riverpod
Future<SonarQubeIssueContext> sonarQubeIssueContext(
  Ref ref,
  SonarQubeIssue issue,
) async {
  final result = await ref
      .watch(sonarQubeRepositoryProvider)
      .fetchIssueContext(issue);
  return result.fold((context) => context, (failure) => throw failure);
}
