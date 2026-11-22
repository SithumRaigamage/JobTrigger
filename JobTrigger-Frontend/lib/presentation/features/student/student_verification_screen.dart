import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/student/student_application.dart';
import '../../../domain/student/student_document.dart';
import '../../common_widgets/grouped_card.dart';
import '../../common_widgets/inline_alert.dart';
import '../../common_widgets/labeled_field.dart';
import '../../common_widgets/responsive_center.dart';
import 'student_flow_notifier.dart';
import 'student_status_notifier.dart';

/// Phase 21 (SP-4): Subscription → Verify student status. Free Pro for a year
/// for verified students: a code to a university email first, a student ID or
/// enrolment letter as the fallback. Reachable only when billing is available
/// (`billingAvailableProvider`, via the router).
class StudentVerificationScreen extends ConsumerStatefulWidget {
  const StudentVerificationScreen({super.key});

  @override
  ConsumerState<StudentVerificationScreen> createState() =>
      _StudentVerificationScreenState();
}

class _StudentVerificationScreenState
    extends ConsumerState<StudentVerificationScreen> {
  /// After a rejection, "Try again" shows the form once more.
  bool _tryAgain = false;

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(studentStatusNotifierProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ResponsiveCenter(
              child: Padding(
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
            ),
            Expanded(
              child: ResponsiveCenter(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Student plan',
                        style: textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...switch (status) {
                      AsyncData(:final value) => _forApplication(value),
                      AsyncError(:final error) => [
                        InlineAlert(
                          message: error is AppFailure
                              ? error.message
                              : "Couldn't load your student status.",
                          liveRegion: true,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => ref
                              .read(studentStatusNotifierProvider.notifier)
                              .refresh(),
                          child: const Text('Try again'),
                        ),
                      ],
                      _ => const [Center(child: CircularProgressIndicator())],
                    },
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _forApplication(StudentApplication application) {
    return switch (application.statusAt(DateTime.now())) {
      StudentStatus.pending => [_pending(application)],
      StudentStatus.approved => [_approved(application)],
      StudentStatus.expired => [_expired()],
      StudentStatus.rejected when !_tryAgain => [_rejected(application)],
      _ => [const _VerifyFlow()],
    };
  }

  Widget _pending(StudentApplication application) {
    // US-STU-01: a verified university email waits for review too.
    return _Message(
      icon: Icons.hourglass_top_rounded,
      title: 'Pending review',
      body: application.method == StudentMethod.email
          ? 'Your university email is verified. We review every application '
                "by hand, so it can take a few days. You'll see the result here."
          : "We've received your student document. We review them by hand, so "
                "it can take a few days. You'll see the result here.",
    );
  }

  Widget _approved(StudentApplication application) {
    final end = application.expiresAt;
    return _Message(
      icon: Icons.verified_rounded,
      title: 'You have JobTrigger Pro as a student',
      body: end == null
          ? 'Your student year is active.'
          : 'Your free year runs until ${formatStudentDate(end)}.',
    );
  }

  Widget _expired() => const _Message(
    icon: Icons.event_busy_rounded,
    title: 'Your student year has ended',
    body:
        'The student plan is one free year per person, so your account is '
        'back on the Free plan.',
  );

  Widget _rejected(StudentApplication application) {
    final reason = application.rejectionReason;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InlineAlert(
          title: application.method == StudentMethod.email
              ? "We couldn't approve your application"
              : "We couldn't approve your document",
          message: reason == null || reason.isEmpty
              ? 'Try again with a clearer photo or a different document.'
              : reason,
          liveRegion: true,
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () => setState(() => _tryAgain = true),
          child: const Text('Try again'),
        ),
      ],
    );
  }
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
];

/// "12 Nov 2027".
String formatStudentDate(DateTime date) {
  final d = date.toLocal();
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    return GroupedCard(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28, color: t.textSecondary),
              const SizedBox(height: 12),
              Semantics(
                header: true,
                child: Text(title, style: textTheme.titleMedium),
              ),
              const SizedBox(height: 6),
              Text(body, style: textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

/// The steps: email → code, or a document.
class _VerifyFlow extends ConsumerStatefulWidget {
  const _VerifyFlow();

  @override
  ConsumerState<_VerifyFlow> createState() => _VerifyFlowState();
}

class _VerifyFlowState extends ConsumerState<_VerifyFlow> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _name = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(studentFlowNotifierProvider);
    final notifier = ref.read(studentFlowNotifierProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);

    Widget error(AppFailure? failure) => failure == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InlineAlert(message: failure.message, liveRegion: true),
          );

    Widget button(String label, VoidCallback? onPressed, {bool busy = false}) =>
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: busy ? null : onPressed,
          child: busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(label),
        );

    return switch (flow) {
      StudentFlowEmail(:final failure, :final busy) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Students get JobTrigger Pro free for one year. Verify with your '
            'university email.',
            style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
          ),
          const SizedBox(height: 20),
          error(failure),
          LabeledField(
            label: 'University email',
            child: TextField(
              key: const Key('student_email_field'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => notifier.submitEmail(_email.text),
              decoration: const InputDecoration(
                hintText: 'you@university.ac.lk',
              ),
            ),
          ),
          const SizedBox(height: 20),
          button(
            'Send code',
            () => notifier.submitEmail(_email.text),
            busy: busy,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: notifier.useDocument,
              child: const Text('No university email? Upload a student ID'),
            ),
          ),
        ],
      ),
      StudentFlowCode(
        :final email,
        :final failure,
        :final busy,
        :final resent,
      ) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'We sent a 6-digit code to $email. It works for 10 minutes.',
              style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
            ),
            const SizedBox(height: 20),
            if (resent)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: InlineAlert(
                  message: 'A new code is on its way.',
                  tone: StatusTone.success,
                  icon: Icons.mark_email_read_outlined,
                  liveRegion: true,
                ),
              ),
            error(failure),
            LabeledField(
              label: 'Code',
              child: TextField(
                key: const Key('student_code_field'),
                controller: _code,
                keyboardType: TextInputType.number,
                autocorrect: false,
                maxLength: 6,
                autofillHints: const [AutofillHints.oneTimeCode],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => notifier.confirmCode(_code.text),
                decoration: const InputDecoration(
                  hintText: '123456',
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(height: 20),
            button(
              'Verify',
              () => notifier.confirmCode(_code.text),
              busy: busy,
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: busy ? null : notifier.resendCode,
                child: const Text('Send a new code'),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: busy ? null : notifier.backToEmail,
                child: const Text('Use a different email'),
              ),
            ),
          ],
        ),
      StudentFlowDocument(
        :final domainNotListed,
        :final document,
        :final problem,
        :final nameProblem,
        :final failure,
        :final busy,
      ) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (domainNotListed) ...[
              const InlineAlert(
                message:
                    "We can't check that email domain automatically. Upload "
                    'a student ID or an enrolment letter instead.',
                tone: StatusTone.neutral,
                icon: Icons.info_outline_rounded,
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Upload a photo or PDF of your student ID or enrolment letter '
              '(JPG, PNG or PDF, up to 5 MB). We review it by hand and delete '
              'the file 30 days after we decide.',
              style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
            ),
            const SizedBox(height: 20),
            if (problem != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InlineAlert(
                  message: documentProblemMessage(problem),
                  liveRegion: true,
                ),
              ),
            error(failure),
            LabeledField(
              label: 'Full name as on your student ID',
              child: TextField(
                key: const Key('student_name_field'),
                controller: _name,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'As printed on your ID',
                  errorText: nameProblem
                      ? 'Enter your name as it appears on the ID.'
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const Key('student_choose_file'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: busy ? null : notifier.chooseDocument,
              icon: const Icon(Icons.attach_file_rounded),
              label: Text(document == null ? 'Choose file' : 'Choose another'),
            ),
            if (document != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Selected: ${document.name}',
                  key: const Key('student_selected_file'),
                  style: textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 20),
            button(
              'Send for review',
              document == null
                  ? null
                  : () => notifier.uploadDocument(_name.text),
              busy: busy,
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: busy ? null : notifier.backToEmail,
                child: const Text('Use a university email instead'),
              ),
            ),
          ],
        ),
      StudentFlowDone() => const SizedBox.shrink(),
    };
  }
}

/// The copy for a document refused on the phone.
String documentProblemMessage(StudentDocumentProblem problem) =>
    switch (problem) {
      StudentDocumentProblem.empty => 'That file is empty. Choose another.',
      StudentDocumentProblem.tooLarge => 'File too large, max 5 MB.',
      StudentDocumentProblem.wrongType =>
        'Only JPG, PNG or PDF files are accepted.',
    };
