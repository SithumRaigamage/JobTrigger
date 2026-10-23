import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_message.dart';
import '../../../domain/credential/github_credential.dart';
import '../../common_widgets/labeled_field.dart';
import '../../common_widgets/secret_reentry_notice.dart';
import '../../common_widgets/toast_controller.dart';
import 'edit_sheet.dart';
import 'github_credential_form_notifier.dart';
import 'test_github_connection_notifier.dart';

/// Laid out like the Jenkins server sheet (`UI-UX/screens/21-edit-server-sheet`,
/// see [showEditSheet]). [existing] is null when adding a new credential,
/// non-null when editing. Completes with `true` when the user asked to
/// delete [existing].
Future<bool?> showGitHubCredentialEditBottomSheet(
  BuildContext context, {
  GitHubCredential? existing,
}) =>
    showEditSheet(context, GitHubCredentialEditBottomSheet(existing: existing));

class GitHubCredentialEditBottomSheet extends ConsumerStatefulWidget {
  const GitHubCredentialEditBottomSheet({super.key, this.existing});

  final GitHubCredential? existing;

  @override
  ConsumerState<GitHubCredentialEditBottomSheet> createState() =>
      _GitHubCredentialEditBottomSheetState();
}

class _GitHubCredentialEditBottomSheetState
    extends ConsumerState<GitHubCredentialEditBottomSheet> {
  late final _labelController = TextEditingController(
    text: widget.existing?.label,
  );
  // Never pre-filled with the real secret when editing — matches
  // ServerEditBottomSheet's password field exactly.
  late final _tokenController = TextEditingController();
  late final _defaultOwnerController = TextEditingController(
    text: widget.existing?.defaultOwner,
  );
  late bool _isDefault = widget.existing?.isDefault ?? false;

  bool get _isEditing => widget.existing != null;

  /// AUD-63: the backend could not decrypt the stored token.
  bool get _needsReentry => widget.existing?.needsReentry ?? false;

  @override
  void dispose() {
    _labelController.dispose();
    _tokenController.dispose();
    _defaultOwnerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(gitHubCredentialFormNotifierProvider, (previous, next) {
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

    final saveState = ref.watch(gitHubCredentialFormNotifierProvider);
    final testState = ref.watch(testGitHubConnectionNotifierProvider);

    return EditSheetFrame(
      title: _isEditing ? 'Edit GitHub credential' : 'Add GitHub credential',
      saveLabel: _isEditing ? 'Save' : 'Add',
      saving: saveState.isLoading,
      onSave: _save,
      deleteLabel: _isEditing ? 'Delete credential' : null,
      children: [
        LabeledField(
          label: 'Label',
          child: TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              hintText: 'Personal, Work org, etc.',
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_needsReentry) ...[
          SecretReentryNotice(
            style: Theme.of(context).textTheme.bodySmall,
            detail:
                'The stored token could not be read, so it has to be '
                'entered again before this credential can be used.',
          ),
          const SizedBox(height: 12),
        ],
        LabeledField(
          label: 'Personal access token',
          helper: 'Stored encrypted. Needs repo and workflow scopes.',
          child: SecretTextField(
            controller: _tokenController,
            noun: 'token',
            // AUD-63: "leave blank to keep the current token" is a lie
            // when the current token can't be read — there's nothing to
            // keep.
            hintText: _needsReentry
                ? 'Enter the token again'
                : _isEditing
                ? 'Leave blank to keep the current token'
                : 'ghp_… or github_pat_…',
          ),
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Default org or owner (optional)',
          child: TextField(
            controller: _defaultOwnerController,
            autocorrect: false,
            decoration: const InputDecoration(hintText: 'octocat'),
          ),
        ),
        const SizedBox(height: 4),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Set as default credential'),
          value: _isDefault,
          onChanged: (value) => setState(() => _isDefault = value),
        ),
        const SizedBox(height: 8),
        ConnectionTest<String>(
          state: testState,
          onTest: _testConnection,
          describe: (login) => 'Connected — signed in as $login',
        ),
      ],
    );
  }

  void _testConnection() {
    ref
        .read(testGitHubConnectionNotifierProvider.notifier)
        .test(token: _tokenController.text.trim());
  }

  void _save() {
    final defaultOwner = _defaultOwnerController.text.trim();
    // Editing with a blank token field means "keep the current secret" --
    // the backend PUT only overwrites fields it's sent, but this repo's
    // add/update methods always send `token`, so fall back to the
    // existing (already-known, never displayed) secret rather than
    // overwriting it with an empty string.
    final token = _tokenController.text.trim().isEmpty
        ? (widget.existing?.secret ?? '')
        : _tokenController.text.trim();
    ref
        .read(gitHubCredentialFormNotifierProvider.notifier)
        .save(
          id: widget.existing?.id,
          label: _labelController.text.trim(),
          secret: token,
          defaultOwner: defaultOwner.isEmpty ? null : defaultOwner,
          isDefault: _isDefault,
          // AUD-63: the stored token couldn't be decrypted, so a blank
          // field is a refusal to save, not "keep the current token".
          needsReentry: _needsReentry,
        );
  }
}
