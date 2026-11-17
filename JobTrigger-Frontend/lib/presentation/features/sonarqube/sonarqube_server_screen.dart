import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import '../../common_widgets/section_label.dart';
import '../../navigation/main_scaffold.dart';
import 'sonarqube_quality_notifiers.dart';

/// `US-SQ-SERVER-01`: the server's version and status, so a problem can be
/// blamed on the right side. Only endpoints any signed-in user may read.
class SonarQubeServerScreen extends ConsumerWidget {
  const SonarQubeServerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(sonarQubeServerInfoProvider);
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ResponsiveCenter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                    Semantics(
                      header: true,
                      child: Text('Server', style: textTheme.headlineMedium),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: info.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: ConnectionErrorView(
                      message: describeError(error),
                      onRetry: () =>
                          ref.invalidate(sonarQubeServerInfoProvider),
                    ),
                  ),
                  data: (info) => ListView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      16 + glassNavBarClearance(context),
                    ),
                    children: [
                      const SectionLabel('This server'),
                      const SizedBox(height: 10),
                      GlassSurface.card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Row(
                              label: 'Version',
                              value: info.version.isEmpty
                                  ? 'Not reported'
                                  : info.version,
                              mono: true,
                            ),
                            const SizedBox(height: 10),
                            _Row(label: 'Status', value: info.statusLabel),
                            if (info.hint.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                info.hint,
                                style: textTheme.bodySmall?.copyWith(
                                  color: t.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Edition is not shown: the endpoints that report it '
                        'need administrator rights.',
                        style: textTheme.bodySmall?.copyWith(
                          color: t.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: t.textMuted),
          ),
        ),
        Text(
          value,
          style: mono
              ? AppTypography.mono(textTheme.bodyMedium)
              : textTheme.bodyMedium,
        ),
      ],
    );
  }
}
