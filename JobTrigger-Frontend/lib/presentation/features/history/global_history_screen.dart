import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/no_active_server_view.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/app_routes.dart';
import '../settings/active_server_notifier.dart';
import 'global_history_notifier.dart';
import 'history_tile.dart';

/// Ported from `GlobalHistoryView.swift`.
class GlobalHistoryScreen extends ConsumerWidget {
  const GlobalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeServer = ref.watch(activeServerNotifierProvider);
    final backButton = IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: 'Tool Selection',
      onPressed: () => context.go(AppRoutes.toolSelection),
    );

    if (activeServer == null) {
      return Scaffold(
        appBar: AppBar(leading: backButton, title: const Text('History')),
        body: const Center(child: NoActiveServerView()),
      );
    }

    final historyAsync = ref.watch(globalHistoryNotifierProvider);

    return Scaffold(
      appBar: AppBar(leading: backButton, title: const Text('History')),
      body: ResponsiveCenter(
        child: historyAsync.when(
          data: (entries) {
            if (entries.isEmpty) {
              return const Center(child: Text('No build history yet'));
            }
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(globalHistoryNotifierProvider.notifier).refresh(),
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return HistoryTile(
                    key: ValueKey(entry.id),
                    jenkinsBuild: entry.build,
                    jobName: entry.jobName,
                    onTap: () =>
                        context.push(AppRoutes.buildLog, extra: entry.build),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: ConnectionErrorView(
              message: describeError(error),
              onRetry: () =>
                  ref.read(globalHistoryNotifierProvider.notifier).refresh(),
            ),
          ),
        ),
      ),
    );
  }
}
