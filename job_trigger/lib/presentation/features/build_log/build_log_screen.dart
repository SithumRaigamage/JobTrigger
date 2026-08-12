import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/error/error_message.dart';
import '../../../domain/jenkins/jenkins_build.dart';
import '../../common_widgets/connection_error_view.dart';
import 'build_log_notifier.dart';
import 'console_log_viewer.dart';

/// Ported from `BuildLogView.swift`. [jenkinsBuild] comes from navigation
/// `extra` (from `JobDetailScreen`).
class BuildLogScreen extends ConsumerWidget {
  const BuildLogScreen({super.key, required this.jenkinsBuild});

  final JenkinsBuild jenkinsBuild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logAsync = ref.watch(buildLogNotifierProvider(jenkinsBuild.url));
    final text = logAsync.value;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Build #${jenkinsBuild.number}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy log',
            onPressed: text == null ? null : () => _copy(context, text),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share log',
            onPressed: text == null
                ? null
                : () => _share(text, jenkinsBuild.number),
          ),
        ],
      ),
      body: logAsync.when(
        data: (text) => ConsoleLogViewer(text: text),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: ConnectionErrorView(
            message: describeError(error),
            onRetry: () =>
                ref.invalidate(buildLogNotifierProvider(jenkinsBuild.url)),
          ),
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Log copied to clipboard')));
    }
  }

  Future<void> _share(String text, int buildNumber) => SharePlus.instance.share(
    ShareParams(text: text, subject: 'Build #$buildNumber log'),
  );
}
