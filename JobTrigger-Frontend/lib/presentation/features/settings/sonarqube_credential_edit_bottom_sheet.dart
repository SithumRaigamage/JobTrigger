import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_message.dart';
import '../../../domain/credential/sonarqube_credential.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/toast_controller.dart';
import 'sonarqube_credential_form_notifier.dart';
import 'test_sonarqube_connection_notifier.dart';

/// Mirrors `showGitHubCredentialEditBottomSheet`'s shape exactly, including
/// the wide-window `Dialog` vs. narrow-window bottom-sheet split and
/// `useRootNavigator: true`. [existing] is null when adding a new
/// credential, non-null when editing.
Future<void> showSonarQubeCredentialEditBottomSheet(
  BuildContext context, {
  SonarQubeCredential? existing,
}) {
  const wideBreakpoint = 900.0;
  if (MediaQuery.sizeOf(context).width >= wideBreakpoint) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassSurface.chrome(
          borderRadius: BorderRadius.circular(20),
          child: SonarQubeCredentialEditBottomSheet(existing: existing),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => GlassSurface.chrome(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SonarQubeCredentialEditBottomSheet(existing: existing),
    ),
  );
}

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
  bool _obscureToken = true;

  bool get _isEditing => widget.existing != null;

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

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isEditing
                      ? 'Edit SonarQube Credential'
                      : 'Add SonarQube Credential',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    hintText: 'Personal, Work Org, etc.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _baseUrlController,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Instance URL',
                    hintText: 'https://sonarcloud.io',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tokenController,
                  obscureText: _obscureToken,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'User Token',
                    hintText: _isEditing
                        ? 'Leave blank to keep the current token'
                        : 'squ_…',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureToken
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      tooltip: _obscureToken ? 'Show token' : 'Hide token',
                      onPressed: () =>
                          setState(() => _obscureToken = !_obscureToken),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _defaultOrganizationController,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Organization (optional)',
                    hintText: 'Required for SonarCloud, unused for self-hosted Server',
                    border: OutlineInputBorder(),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Set as default credential'),
                  value: _isDefault,
                  onChanged: (value) => setState(() => _isDefault = value),
                ),
                const SizedBox(height: 8),
                _TestSonarQubeConnectionStatus(state: testState),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.wifi_tethering),
                  label: const Text('Test Connection'),
                  onPressed: testState.isLoading ? null : _testConnection,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: saveState.isLoading ? null : _save,
                  child: saveState.isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEditing ? 'Save' : 'Add'),
                ),
              ],
            ),
          ),
        ),
      ),
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
        );
  }
}

class _TestSonarQubeConnectionStatus extends StatelessWidget {
  const _TestSonarQubeConnectionStatus({required this.state});

  final AsyncValue<bool?> state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      AsyncData(value: null) => const SizedBox.shrink(),
      AsyncData() => const Text(
        'Connected',
        style: TextStyle(color: Colors.green),
      ),
      AsyncLoading() => const Text('Testing...'),
      AsyncError(:final error) => Text(
        'Failed: ${describeError(error)}',
        style: const TextStyle(color: Colors.red),
      ),
    };
  }
}
