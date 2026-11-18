import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_message.dart';
import '../../../core/platform/package_info_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/credentials/active_server_notifier.dart';
import '../../../data/credentials/active_sonarqube_credential_notifier.dart';
import '../../../domain/auth/auth_state.dart';
import '../../../domain/support/support_category.dart';
import '../../../domain/support/support_diagnostics.dart';
import '../../../domain/support/support_ticket.dart';
import '../../common_widgets/external_link.dart';
import '../../common_widgets/grouped_card.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import '../../common_widgets/section_label.dart';
import '../../navigation/main_scaffold.dart';
import '../app_info/app_info_notifier.dart';
import '../auth/auth_notifier.dart';
import '../tool_selection/active_tool_notifier.dart';
import '../tool_selection/ci_tool.dart';
import 'my_support_tickets_notifier.dart';
import 'support_form_notifier.dart';

/// P25-05: one place to report a bug, ask a question, suggest a feature or
/// request a tool. A report is stored on the backend and the owner is emailed
/// it; the plain support address stays available as a fallback.
///
/// Reached from Profile and App Info, and from the tool-selection screen's
/// "Need another tool?", which opens it with [category] preset.
class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key, this.category});

  final SupportCategory? category;

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  late final TextEditingController _subject;
  late final TextEditingController _message;
  late final TextEditingController _email;
  late SupportCategory _category;
  bool _attachDiagnostics = true;
  bool _emailTouched = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _category = widget.category ?? SupportCategory.bug;
    _subject = TextEditingController(
      text: _category == SupportCategory.toolRequest ? 'Tool request: ' : '',
    );
    _message = TextEditingController();
    final auth = ref.read(authNotifierProvider).value;
    _email = TextEditingController(
      text: auth is Authenticated ? auth.user.email : '',
    );
    // The account loads asynchronously: fill the reply address once it is
    // known, unless the user has started typing their own.
    ref.listenManual(authNotifierProvider, (previous, next) {
      final value = next.value;
      if (_emailTouched || _email.text.isNotEmpty) return;
      if (value is Authenticated) _email.text = value.user.email;
    });
  }

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submission = ref.watch(supportFormNotifierProvider);
    final sending = submission.isLoading;
    final sent = submission.value;
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    final supportEmail = ref.watch(appInfoNotifierProvider).value?.supportEmail;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ResponsiveCenter(
          child: Column(
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
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    4,
                    20,
                    16 + glassNavBarClearance(context),
                  ),
                  children: [
                    Semantics(
                      header: true,
                      child: Text('Support', style: textTheme.headlineMedium),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Reports go to the JobTrigger team. Tell us what went '
                      'wrong, or what would make the app better.',
                      style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
                    ),
                    const SizedBox(height: 20),
                    if (sent != null)
                      _SentCard(
                        ticket: sent,
                        replyEmail: _email.text.trim(),
                        onAgain: () {
                          ref
                              .read(supportFormNotifierProvider.notifier)
                              .reset();
                          setState(() => _formError = null);
                        },
                      )
                    else ...[
                      const SectionLabel('What is it about?'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final category in SupportCategory.values)
                            ChoiceChip(
                              label: Text(category.label),
                              selected: _category == category,
                              onSelected: sending
                                  ? null
                                  : (_) => setState(() => _category = category),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _subject,
                        enabled: !sending,
                        maxLength: 120,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          hintText: 'Build log is blank for long jobs',
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _message,
                        enabled: !sending,
                        maxLength: 4000,
                        maxLines: 8,
                        minLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Details',
                          alignLabelWithHint: true,
                          hintText:
                              'What happened, what you expected, and what you '
                              'tried. Do not paste tokens or passwords.',
                        ),
                      ),
                      TextField(
                        controller: _email,
                        enabled: !sending,
                        onChanged: (_) => _emailTouched = true,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Reply to',
                          helperText: 'Where we answer this report',
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _attachDiagnostics,
                        onChanged: sending
                            ? null
                            : (value) =>
                                  setState(() => _attachDiagnostics = value),
                        title: const Text('Attach app details'),
                        subtitle: Text(
                          'Version, tool and platform — never your tokens.\n'
                          '${_diagnosticsSummary()}',
                          style: textTheme.bodySmall?.copyWith(
                            color: t.textMuted,
                          ),
                        ),
                      ),
                      if (_formError case final error?)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            error,
                            style: textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      if (submission.error case final failure?)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            describeError(failure),
                            style: textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: sending ? null : _submit,
                        child: Text(sending ? 'Sending…' : 'Send report'),
                      ),
                    ],
                    if (supportEmail != null) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => openExternalLink(
                            ref,
                            Uri.parse('mailto:$supportEmail'),
                          ),
                          icon: const Icon(
                            Icons.mail_outline_rounded,
                            size: 18,
                          ),
                          label: Text('Or email $supportEmail'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _RecentReports(
                      onRetry: () => ref
                          .read(mySupportTicketsNotifierProvider.notifier)
                          .refresh(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final subject = _subject.text.trim();
    final message = _message.text.trim();
    if (subject.isEmpty) {
      setState(() => _formError = 'Add a short subject.');
      return;
    }
    if (message.isEmpty) {
      setState(() => _formError = 'Describe the issue or request.');
      return;
    }
    setState(() => _formError = null);
    FocusScope.of(context).unfocus();
    final ticket = await ref
        .read(supportFormNotifierProvider.notifier)
        .submit(
          category: _category,
          subject: subject,
          message: message,
          replyEmail: _email.text.trim(),
          diagnostics: _attachDiagnostics ? _diagnostics() : null,
        );
    if (!mounted || ticket == null) return;
    _subject.clear();
    _message.clear();
  }

  SupportDiagnostics _diagnostics() {
    final info = ref.read(packageInfoProvider).value;
    final tool = ref.read(activeToolNotifierProvider) ?? CiTool.jenkins;
    final String? serverUrl;
    if (tool == CiTool.githubActions) {
      serverUrl = null;
    } else if (tool == CiTool.sonarqube) {
      serverUrl = ref.read(activeSonarQubeCredentialNotifierProvider)?.baseUrl;
    } else {
      serverUrl = ref.read(activeServerNotifierProvider)?.jenkinsURL;
    }
    return SupportDiagnostics(
      appVersion: info?.version ?? '',
      buildNumber: info?.buildNumber ?? '',
      tool: tool.name,
      platform: defaultTargetPlatform.name,
      serverHost: hostOnly(serverUrl),
    );
  }

  /// The same line the switch's subtitle shows, so nothing is attached
  /// unseen. Read-only and cheap; rebuilt with the screen.
  String _diagnosticsSummary() => _diagnostics().summary;
}

/// Shown once a ticket exists: the id, where the reply goes, and a way back
/// to the form.
class _SentCard extends StatelessWidget {
  const _SentCard({
    required this.ticket,
    required this.replyEmail,
    required this.onAgain,
  });

  final SupportTicket ticket;
  final String replyEmail;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return GlassSurface.card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: t.success.foreground,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Report sent', style: textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            replyEmail.isEmpty
                ? 'We reply to the email on your account.'
                : 'We reply to $replyEmail.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Ticket ${ticket.id}',
            style: textTheme.bodySmall?.copyWith(color: t.textMuted),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onAgain, child: const Text('Send another')),
        ],
      ),
    );
  }
}

/// Earlier reports and their status. Loading and failure stay quiet: this is
/// context, not the reason the user is here.
class _RecentReports extends ConsumerWidget {
  const _RecentReports({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = ref.watch(mySupportTicketsNotifierProvider);
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    return mine.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => TextButton(
        onPressed: onRetry,
        child: const Text("Couldn't load earlier reports. Retry"),
      ),
      data: (tickets) {
        if (tickets.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionLabel('Your reports'),
            const SizedBox(height: 10),
            GroupedCard(
              children: [
                for (final ticket in tickets)
                  ListTile(
                    title: Text(
                      ticket.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      ticket.createdAt == null
                          ? ticket.statusLabel
                          : '${ticket.statusLabel} · ${_date(ticket.createdAt!)}',
                      style: textTheme.bodySmall?.copyWith(color: t.textMuted),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  static String _date(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}';
  }
}
