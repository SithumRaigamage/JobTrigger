import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_failure.dart';
import '../../../domain/admin_review/admin_student_application.dart';
import '../../common_widgets/grouped_card.dart';
import '../../common_widgets/inline_alert.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/app_routes.dart';
import '../student/student_verification_screen.dart' show formatStudentDate;
import 'admin_applications_notifier.dart';
import 'admin_review_text.dart';

/// US-STU-02/03: Profile → Student applications (super admin only). The
/// pending queue and the history, both methods, newest first.
class AdminApplicationsScreen extends ConsumerWidget {
  const AdminApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(adminFilterNotifierProvider);
    final applications = ref.watch(adminApplicationsNotifierProvider(filter));
    final textTheme = Theme.of(context).textTheme;

    Future<void> refresh() =>
        ref.read(adminApplicationsNotifierProvider(filter).notifier).refresh();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ResponsiveCenter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Semantics(
                  header: true,
                  child: Text(
                    'Student applications',
                    style: textTheme.headlineMedium,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    for (final option in AdminStatusFilter.values) ...[
                      ChoiceChip(
                        label: Text(option.label),
                        selected: filter == option,
                        showCheckmark: false,
                        onSelected: (_) => ref
                            .read(adminFilterNotifierProvider.notifier)
                            .select(option),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    children: switch (applications) {
                      AsyncData(:final value) when value.isEmpty => const [
                        Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: Text(
                            'No applications here.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      AsyncData(:final value) => [
                        GroupedCard(
                          children: [
                            for (final item in value) _Row(item: item),
                          ],
                        ),
                      ],
                      AsyncError(:final error) => [
                        InlineAlert(
                          message: error is AppFailure
                              ? error.message
                              : "Couldn't load the applications.",
                          liveRegion: true,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: refresh,
                          child: const Text('Try again'),
                        ),
                      ],
                      _ => const [
                        Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ],
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
}

class _Row extends StatelessWidget {
  const _Row({required this.item});

  final AdminStudentApplication item;

  @override
  Widget build(BuildContext context) {
    final decided = decisionLine(item);
    return ListTile(
      key: Key('admin_application_${item.id}'),
      title: Text(item.title, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.accountEmail ?? '(account deleted)',
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${methodLabel(item.method)} · ${statusLabel(item.status)} · '
            'submitted ${formatStudentDate(item.submittedAt)}',
          ),
          if (decided != null) Text(decided),
        ],
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () =>
          context.push(AppRoutes.adminStudentApplication, extra: item.id),
    );
  }
}
