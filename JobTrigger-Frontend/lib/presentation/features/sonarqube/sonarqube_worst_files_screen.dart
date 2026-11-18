import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/error_message.dart';
import '../../../core/error/result.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/sonarqube_repository_impl.dart';
import '../../../domain/sonarqube/sonarqube_issue.dart';
import '../../../domain/sonarqube/sonarqube_project.dart';
import '../../../domain/sonarqube/sonarqube_worst_files.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/main_scaffold.dart';
import '../../../data/credentials/active_sonarqube_credential_notifier.dart';
import '../../common_widgets/tool_server_credential_header.dart';

part 'sonarqube_worst_files_screen.g.dart';

/// A project's worst files for one measure (`US-SQ-QUALITY-12`).
@riverpod
Future<SonarQubeWorstFiles> sonarQubeWorstFiles(
  Ref ref,
  String projectKey,
  String metric,
) async {
  final definition = sonarQubeFileMetrics.firstWhere(
    (m) => m.metric == metric,
    orElse: () => sonarQubeFileMetrics.first,
  );
  final result = await ref
      .watch(sonarQubeRepositoryProvider)
      .fetchWorstFiles(projectKey, definition);
  return result.fold((files) => files, (failure) => throw failure);
}

/// Project page → *Worst files*: where to start, ranked on the server, with a
/// tap that opens the file's open issues.
class SonarQubeWorstFilesScreen extends ConsumerStatefulWidget {
  const SonarQubeWorstFilesScreen({required this.project, super.key});

  final SonarQubeProject project;

  @override
  ConsumerState<SonarQubeWorstFilesScreen> createState() =>
      _SonarQubeWorstFilesScreenState();
}

class _SonarQubeWorstFilesScreenState
    extends ConsumerState<SonarQubeWorstFilesScreen> {
  SonarQubeFileMetric _metric = sonarQubeFileMetrics.first;

  @override
  Widget build(BuildContext context) {
    final credential = ref.watch(activeSonarQubeCredentialNotifierProvider);
    final filesAsync = ref.watch(
      sonarQubeWorstFilesProvider(widget.project.key, _metric.metric),
    );
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ResponsiveCenter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (credential != null)
                SonarQubeCredentialHeader(
                  credential: credential,
                  onSwitch: (chosen) => ref
                      .read(activeSonarQubeCredentialNotifierProvider.notifier)
                      .setActiveCredential(chosen),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 28),
                      tooltip: 'Back',
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.project.name,
                            style: textTheme.bodySmall?.copyWith(
                              color: t.textMuted,
                            ),
                          ),
                          Semantics(
                            header: true,
                            child: Text(
                              'Worst files',
                              style: textTheme.headlineMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final metric in sonarQubeFileMetrics)
                      ChoiceChip(
                        label: Text(metric.label),
                        selected: metric.metric == _metric.metric,
                        onSelected: (_) => setState(() => _metric = metric),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: ConnectionErrorView(
                      message: describeError(error),
                      onRetry: () => ref.invalidate(
                        sonarQubeWorstFilesProvider(
                          widget.project.key,
                          _metric.metric,
                        ),
                      ),
                    ),
                  ),
                  data: (files) => files.files.isEmpty
                      ? Center(
                          child: Text(
                            'No files measured for this yet',
                            style: textTheme.bodyMedium?.copyWith(
                              color: t.textMuted,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            0,
                            20,
                            16 + glassNavBarClearance(context),
                          ),
                          itemCount: files.files.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final file = files.files[index];
                            return _FileRow(
                              path: file.path,
                              value: files.format(file.value),
                              onTap: () => _showIssues(context, file),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showIssues(BuildContext context, SonarQubeFileMeasures file) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => _FileIssuesSheet(
          componentKey: file.componentKey(widget.project.key),
          path: file.path,
        ),
      );
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.path,
    required this.value,
    required this.onTap,
  });

  final String path;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassSurface.card(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        title: Text(
          path,
          style: AppTypography.mono(
            textTheme.bodyMedium,
          ).copyWith(fontSize: 13),
        ),
        trailing: Text(value, style: textTheme.titleMedium),
      ),
    );
  }
}

class _FileIssuesSheet extends ConsumerWidget {
  const _FileIssuesSheet({required this.componentKey, required this.path});

  final String componentKey;
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: FutureBuilder<Result<SonarQubeIssuePage, AppFailure>>(
          future: ref
              .read(sonarQubeRepositoryProvider)
              .fetchFileIssues(componentKey),
          builder: (context, snapshot) {
            final Widget body;
            if (snapshot.connectionState != ConnectionState.done) {
              body = const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            } else {
              final result = snapshot.data;
              if (result is Err<SonarQubeIssuePage, AppFailure>) {
                body = Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(describeError(result.error)),
                );
              } else if (result is Ok<SonarQubeIssuePage, AppFailure>) {
                final issues = result.value.issues;
                body = issues.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No open issues in this file',
                          style: textTheme.bodyMedium?.copyWith(
                            color: t.textMuted,
                          ),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(bottom: 16),
                        children: [
                          for (final issue in issues)
                            ListTile(
                              title: Text(
                                issue.message,
                                style: textTheme.bodyMedium,
                              ),
                              subtitle: Text(
                                [
                                  issue.type,
                                  issue.severity,
                                  if (issue.line != null) 'line ${issue.line}',
                                ].join(' · '),
                                style: textTheme.bodySmall?.copyWith(
                                  color: t.textMuted,
                                ),
                              ),
                            ),
                        ],
                      );
              } else {
                body = const SizedBox.shrink();
              }
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    path,
                    style: AppTypography.mono(
                      textTheme.bodySmall,
                    ).copyWith(color: t.textMuted),
                  ),
                ),
                Flexible(child: body),
              ],
            );
          },
        ),
      ),
    );
  }
}
