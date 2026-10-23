import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_message.dart';
import '../../../domain/credential/jenkins_server.dart';
import '../../../domain/credential/jenkins_url.dart';
import '../../../domain/credential/token_hygiene.dart';
import '../../../core/theme/app_typography.dart';
import '../../common_widgets/cleartext_warning.dart';
import '../../common_widgets/external_link.dart';
import '../../common_widgets/labeled_field.dart';
import '../../common_widgets/secret_reentry_notice.dart';
import '../../common_widgets/toast_controller.dart';
import 'edit_sheet.dart';
import 'server_form_notifier.dart';
import 'test_connection_notifier.dart';

/// Ported from the add/edit sheet in `SettingsView.swift`, laid out to the
/// P14 design (`UI-UX/screens/21-edit-server-sheet`). [existing] is null
/// when adding a new server, non-null when editing one. Completes with
/// `true` when the user asked to delete [existing] (see [showEditSheet]).
Future<bool?> showServerEditBottomSheet(
  BuildContext context, {
  JenkinsServer? existing,
}) => showEditSheet(context, ServerEditBottomSheet(existing: existing));

class ServerEditBottomSheet extends ConsumerStatefulWidget {
  const ServerEditBottomSheet({super.key, this.existing});

  final JenkinsServer? existing;

  @override
  ConsumerState<ServerEditBottomSheet> createState() =>
      _ServerEditBottomSheetState();
}

class _ServerEditBottomSheetState extends ConsumerState<ServerEditBottomSheet> {
  late final _serverNameController = TextEditingController(
    text: widget.existing?.serverName,
  );
  late final _jenkinsURLController = TextEditingController(
    text: widget.existing?.jenkinsURL,
  );
  late final _usernameController = TextEditingController(
    text: widget.existing?.username,
  );
  late final _passwordController = TextEditingController(
    text: widget.existing?.secret,
  );
  late final _paramTokenController = TextEditingController(
    text: widget.existing?.paramToken,
  );
  late bool _isDefault = widget.existing?.isDefault ?? false;

  bool get _isEditing => widget.existing != null;

  /// AUD-63: the backend could not decrypt the stored secret.
  bool get _needsReentry => widget.existing?.needsReentry ?? false;

  @override
  void dispose() {
    _serverNameController.dispose();
    _jenkinsURLController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _paramTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(serverFormNotifierProvider, (previous, next) {
      switch (next) {
        case AsyncError(:final error):
          ref
              .read(toastControllerProvider)
              .show(
                type: ToastType.error,
                title: 'Save Failed',
                message: describeError(error),
              );
        case AsyncData() when previous is AsyncLoading:
          Navigator.of(context).pop();
        case _:
      }
    });

    final saveState = ref.watch(serverFormNotifierProvider);
    final testState = ref.watch(testConnectionNotifierProvider);

    final url = _jenkinsURLController.text;
    return EditSheetFrame(
      title: _isEditing ? 'Edit server' : 'Add server',
      saveLabel: _isEditing ? 'Save' : 'Add',
      saving: saveState.isLoading,
      onSave: _save,
      deleteLabel: _isEditing ? 'Delete server' : null,
      children: [
        LabeledField(
          label: 'Name',
          child: TextField(
            controller: _serverNameController,
            decoration: const InputDecoration(hintText: 'My Jenkins server'),
          ),
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Server URL',
          child: TextField(
            controller: _jenkinsURLController,
            keyboardType: TextInputType.url,
            autocorrect: false,
            style: AppTypography.mono(Theme.of(context).textTheme.bodyLarge),
            // Re-check the URL (AUD-14) as the user types.
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'https://ci.example.com',
              errorText: url.trim().isEmpty ? null : jenkinsUrlProblem(url),
              errorMaxLines: 2,
            ),
          ),
        ),
        if (isCleartextUrl(url))
          const CleartextWarning(
            secretDescription: 'your username and password or token are',
          ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Username',
          child: TextField(controller: _usernameController, autocorrect: false),
        ),
        const SizedBox(height: 16),
        if (_needsReentry) ...[
          SecretReentryNotice(
            style: Theme.of(context).textTheme.bodySmall,
            detail:
                'The stored secret could not be read, so it has to be '
                'entered again before this server can be used.',
          ),
          const SizedBox(height: 12),
        ],
        LabeledField(
          label: 'API token',
          helper:
              'Use a Jenkins API token, not your password. '
              'It’s stored encrypted.',
          child: SecretTextField(
            controller: _passwordController,
            noun: 'token',
            // Re-check the token heuristic as the user types.
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (_passwordController.text.isNotEmpty &&
            !looksLikeJenkinsApiToken(_passwordController.text))
          _PasswordAdvisory(jenkinsUrl: url),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Build token (optional)',
          helper: 'The job’s “Trigger builds remotely” token, if it uses one.',
          child: SecretTextField(
            controller: _paramTokenController,
            noun: 'build token',
          ),
        ),
        const SizedBox(height: 4),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Set as default server'),
          value: _isDefault,
          onChanged: (value) => setState(() => _isDefault = value),
        ),
        const SizedBox(height: 8),
        ConnectionTest<int>(
          state: testState,
          onTest: _testConnection,
          describe: (count) =>
              'Connected — $count job${count == 1 ? '' : 's'} found',
        ),
      ],
    );
  }

  void _testConnection() {
    ref
        .read(testConnectionNotifierProvider.notifier)
        .test(
          jenkinsURL: _jenkinsURLController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );
  }

  void _save() {
    final paramToken = _paramTokenController.text.trim();
    ref
        .read(serverFormNotifierProvider.notifier)
        .save(
          id: widget.existing?.id,
          serverName: _serverNameController.text.trim(),
          jenkinsURL: _jenkinsURLController.text.trim(),
          username: _usernameController.text.trim(),
          secret: _passwordController.text,
          paramToken: paramToken.isEmpty ? null : paramToken,
          isDefault: _isDefault,
          // AUD-63: the stored secret couldn't be decrypted, so there is
          // nothing to fall back to — the user has to type it again.
          needsReentry: _needsReentry,
        );
  }
}

/// AUD-14: `http://` is allowed (LAN servers), but never silently.
/// US-JX-22: a non-blocking nudge towards a revocable API token when the
/// secret looks like an account password.
class _PasswordAdvisory extends ConsumerWidget {
  const _PasswordAdvisory({required this.jenkinsUrl});

  final String jenkinsUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final url = Uri.tryParse(jenkinsUrl.trim());
    final canLink = url != null && url.hasScheme && url.host.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: colorScheme.tertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This looks like a password. Jenkins API tokens are safer — '
                  'they can be revoked without changing your password.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (canLink)
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => openExternalLink(
                      ref,
                      jenkinsTokenPageUrl(jenkinsUrl.trim()),
                    ),
                    child: const Text('Create an API token'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
