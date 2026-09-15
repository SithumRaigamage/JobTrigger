import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/no_active_server_view.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/app_routes.dart';
import '../../navigation/main_scaffold.dart';
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
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(leading: backButton, title: const Text('History')),
        body: Center(
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + kToolbarHeight,
            ),
            child: const NoActiveServerView(),
          ),
        ),
      );
    }

    final historyAsync = ref.watch(globalHistoryNotifierProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(leading: backButton, title: const Text('History')),
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
                padding: EdgeInsets.fromLTRB(
                  8,
                  MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
                  8,
                  8 + glassNavBarClearance(context),
                ),
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
