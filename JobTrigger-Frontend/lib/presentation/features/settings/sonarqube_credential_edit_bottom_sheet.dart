import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_message.dart';
import '../../../domain/credential/sonarqube_credential.dart';
import '../../../domain/credential/sonarqube_url.dart';
import '../../../core/theme/app_typography.dart';
import '../../common_widgets/cleartext_warning.dart';
import '../../common_widgets/labeled_field.dart';
import '../../common_widgets/secret_reentry_notice.dart';
import '../../common_widgets/toast_controller.dart';
import 'edit_sheet.dart';
import 'sonarqube_credential_form_notifier.dart';
import 'test_sonarqube_connection_notifier.dart';

/// Laid out like the Jenkins server sheet (`UI-UX/screens/21-edit-server-sheet`,
/// see [showEditSheet]). [existing] is null when adding a new credential,
/// non-null when editing. Completes with `true` when the user asked to
/// delete [existing].
Future<bool?> showSonarQubeCredentialEditBottomSheet(
  BuildContext context, {
  SonarQubeCredential? existing,
}) => showEditSheet(
  context,
  SonarQubeCredentialEditBottomSheet(existing: existing),
);

class SonarQubeCredentialEditBottomSheet extends ConsumerStatefulWidget {
  const SonarQubeCredentialEditBottomSheet({super.key, this.existing});

  final SonarQubeCredential? existing;

  @override
  ConsumerState<SonarQubeCredentialEditBottomSheet> createState() =>
      _SonarQubeCredentialEditBottomSheetState();
}

class _SonarQubeCredentialEditBottomSheetState
    extends ConsumerState<SonarQubeCredentialEditBottomSheet> {
  late final _labelController = TextEditingController(
    text: widget.existing?.label,
  );
  late final _baseUrlController = TextEditingController(
    text: widget.existing?.baseUrl ?? 'https://sonarcloud.io',
  );
  // Never pre-filled with the real secret when editing — matches
  // GitHubCredentialEditBottomSheet's token field exactly.
  late final _tokenController = TextEditingController();
  late final _defaultOrganizationController = TextEditingController(
    text: widget.existing?.defaultOrganization,
  );
  late bool _isDefault = widget.existing?.isDefault ?? false;

  bool get _isEditing => widget.existing != null;

  /// AUD-63: the backend could not decrypt the stored token.
  bool get _needsReentry => widget.existing?.needsReentry ?? false;

  @override
  void dispose() {
    _labelController.dispose();
    _baseUrlController.dispose();
    _tokenController.dispose();
    _defaultOrganizationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sonarQubeCredentialFormNotifierProvider, (previous, next) {
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

    final saveState = ref.watch(sonarQubeCredentialFormNotifierProvider);
    final testState = ref.watch(testSonarQubeConnectionNotifierProvider);

    final url = _baseUrlController.text;
    return EditSheetFrame(
      title: _isEditing
          ? 'Edit SonarQube credential'
          : 'Add SonarQube credential',
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
        LabeledField(
          label: 'Instance URL',
          child: TextField(
            controller: _baseUrlController,
            keyboardType: TextInputType.url,
            autocorrect: false,
            style: AppTypography.mono(Theme.of(context).textTheme.bodyLarge),
            // Re-check the URL (AUD-52) as the user types.
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'https://sonarcloud.io',
              errorText: url.trim().isEmpty ? null : sonarQubeUrlProblem(url),
              errorMaxLines: 2,
            ),
          ),
        ),
        if (isCleartextUrl(url))
          const CleartextWarning(secretDescription: 'your token is'),
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
          label: 'User token',
          helper: 'Stored encrypted.',
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
                : 'squ_…',
          ),
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Organization (optional)',
          helper: 'Required for SonarCloud, unused for self-hosted Server.',
          child: TextField(
            controller: _defaultOrganizationController,
            autocorrect: false,
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
        ConnectionTest<bool>(
          state: testState,
          onTest: _testConnection,
          describe: (_) => 'Connected',
        ),
      ],
    );
  }

  void _testConnection() {
    ref
        .read(testSonarQubeConnectionNotifierProvider.notifier)
        .test(
          baseUrl: _baseUrlController.text.trim(),
          token: _tokenController.text.trim(),
        );
  }

  void _save() {
    final defaultOrganization = _defaultOrganizationController.text.trim();
    // Editing with a blank token field means "keep the current secret" --
    // the backend PUT only overwrites fields it's sent, but this repo's
    // add/update methods always send `token`, so fall back to the
    // existing (already-known, never displayed) secret rather than
    // overwriting it with an empty string.
    final token = _tokenController.text.trim().isEmpty
        ? (widget.existing?.secret ?? '')
        : _tokenController.text.trim();
    ref
        .read(sonarQubeCredentialFormNotifierProvider.notifier)
        .save(
          id: widget.existing?.id,
          label: _labelController.text.trim(),
          baseUrl: _baseUrlController.text.trim(),
          secret: token,
          defaultOrganization: defaultOrganization.isEmpty
              ? null
              : defaultOrganization,
          isDefault: _isDefault,
          // AUD-63: the stored token couldn't be decrypted, so a blank
          // field is a refusal to save, not "keep the current token".
          needsReentry: _needsReentry,
        );
  }
}
