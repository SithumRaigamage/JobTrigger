import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../navigation/app_routes.dart';
import 'global_history_notifier.dart';
import 'history_tile.dart';

/// Ported from `GlobalHistoryView.swift`.
class GlobalHistoryScreen extends ConsumerWidget {
  const GlobalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(globalHistoryNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: historyAsync.when(
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
    );
  }
}
