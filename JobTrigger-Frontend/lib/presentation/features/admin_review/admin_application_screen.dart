import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/admin_review/admin_student_application.dart';
import '../../../domain/student/student_application.dart';
import '../../common_widgets/confirmation_dialog.dart';
import '../../common_widgets/grouped_card.dart';
import '../../common_widgets/inline_alert.dart';
import '../../common_widgets/responsive_center.dart';
import '../student/student_verification_screen.dart' show formatStudentDate;
import 'admin_application_notifier.dart';
import 'admin_document_view.dart';
import 'admin_review_text.dart';

/// US-STU-02: one student application — the details, the uploaded document
/// (in memory only) and, while pending, Approve and Reject, each confirmed.
class AdminApplicationScreen extends ConsumerWidget {
  const AdminApplicationScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final application = ref.watch(adminApplicationNotifierProvider(id));
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ResponsiveCenter(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 28),
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              Semantics(
                header: true,
                child: Text(
                  'Student application',
                  style: textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 16),
              ...switch (application) {
                AsyncData(:final value) => _body(context, ref, value),
                AsyncError(:final error) => [
                  InlineAlert(
                    message: error is AppFailure
                        ? error.message
                        : "Couldn't load this application.",
                    liveRegion: true,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () =>
                        ref.invalidate(adminApplicationNotifierProvider(id)),
                    child: const Text('Try again'),
                  ),
                ],
                _ => const [Center(child: CircularProgressIndicator())],
              },
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    WidgetRef ref,
    AdminApplicationState state,
  ) {
    final item = state.item;
    final notifier = ref.read(adminApplicationNotifierProvider(id).notifier);
    final decided = state.decided;
    return [
      if (decided != null) ...[
        InlineAlert(
          tone: StatusTone.success,
          icon: Icons.check_circle_outline_rounded,
          liveRegion: true,
          message: switch (decided) {
            AdminDecision.approved =>
              item.expiresAt == null
                  ? 'Approved. The student has Pro for 365 days.'
                  : 'Approved. The student has Pro until '
                        '${formatStudentDate(item.expiresAt!)}.',
            AdminDecision.rejected =>
              'Rejected. The student sees your reason and can apply again.',
          },
        ),
        const SizedBox(height: 16),
      ],
      _Details(item: item),
      if (item.method == StudentMethod.document) ...[
        const SizedBox(height: 16),
        const GroupHeader(title: 'Document'),
        if (item.documentDeleted)
          const Text(
            'Deleted 30 days after the decision. Only a fingerprint is kept.',
          )
        else if (!item.hasDocument)
          const Text('No document.')
        else
          AdminDocumentView(id: item.id),
      ],
      if (state.failure != null) ...[
        const SizedBox(height: 16),
        InlineAlert(message: state.failure!.message, liveRegion: true),
      ],
      if (state.canDecide) ...[
        const SizedBox(height: 20),
        FilledButton(
          key: const Key('admin_approve'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: state.busy
              ? null
              : () async {
                  final confirmed = await showConfirmationDialog(
                    context,
                    title: 'Approve this application?',
                    message:
                        'The student gets JobTrigger Pro free for 365 days '
                        'from now. This can only be given once per person.',
                    confirmLabel: 'Approve',
                  );
                  if (confirmed) await notifier.approve();
                },
          child: state.busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Approve'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          key: const Key('admin_reject'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          onPressed: state.busy
              ? null
              : () async {
                  final reason = await showRejectDialog(context);
                  if (reason != null) await notifier.reject(reason);
                },
          child: const Text('Reject'),
        ),
      ],
    ];
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.item});

  final AdminStudentApplication item;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Status', statusLabel(item.status)),
      ('Method', methodLabel(item.method)),
      if (item.method == StudentMethod.document)
        ('Name on ID', item.fullName ?? '(deleted)'),
      ('Account email', item.accountEmail ?? '(account deleted)'),
      if (item.universityEmail != null)
        ('University email', item.universityEmail!),
      ('Submitted', formatStudentDate(item.submittedAt)),
      if (item.emailVerifiedAt != null)
        ('Email verified', formatStudentDate(item.emailVerifiedAt!)),
      if (item.reviewedAt != null) ...[
        ('Decided', formatStudentDate(item.reviewedAt!)),
        ('Decided by', item.reviewedByEmail ?? '(account deleted)'),
      ],
      if (item.expiresAt != null)
        ('Pro until', formatStudentDate(item.expiresAt!)),
      if (item.rejectionReason != null)
        ('Rejection reason', item.rejectionReason!),
    ];
    final textTheme = Theme.of(context).textTheme;
    return GroupedCard(
      padding: const EdgeInsets.all(16),
      children: [
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: Text(label, style: textTheme.labelLarge),
                ),
                Expanded(
                  child: SelectableText(value, style: textTheme.bodyMedium),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The reject step: the reason the student will see, then "Reject" — the
/// confirmation itself. Null when cancelled.
Future<String?> showRejectDialog(BuildContext context) => showDialog<String>(
  context: context,
  builder: (context) => const _RejectDialog(),
);

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valid = isValidRejectionReason(_reason.text);
    return AlertDialog(
      title: const Text('Reject this application?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('The student sees this reason and can apply again.'),
          const SizedBox(height: 12),
          TextField(
            key: const Key('admin_reject_reason'),
            controller: _reason,
            autofocus: true,
            minLines: 2,
            maxLines: 5,
            maxLength: maxRejectionReasonLength,
            decoration: const InputDecoration(labelText: 'Reason'),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const Key('admin_reject_confirm'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: valid
              ? () => Navigator.of(context).pop(_reason.text.trim())
              : null,
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
