import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_message.dart';
import '../../../domain/credential/github_credential.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/toast_controller.dart';
import 'github_credential_form_notifier.dart';
import 'test_github_connection_notifier.dart';

/// Mirrors `showServerEditBottomSheet`'s shape exactly, including the
/// wide-window `Dialog` vs. narrow-window bottom-sheet split and
/// `useRootNavigator: true` (Settings lives inside `MainScaffold`'s
/// `StatefulShellRoute` branch — without this the sheet attaches to that
/// branch's own nested Navigator and renders underneath the persistent
/// glass nav bar, the same bug already fixed for the Jenkins sheet).
/// [existing] is null when adding a new credential, non-null when editing.
Future<void> showGitHubCredentialEditBottomSheet(
  BuildContext context, {
  GitHubCredential? existing,
}) {
  const wideBreakpoint = 900.0;
  if (MediaQuery.sizeOf(context).width >= wideBreakpoint) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassSurface.chrome(
          borderRadius: BorderRadius.circular(20),
          child: GitHubCredentialEditBottomSheet(existing: existing),
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
      child: GitHubCredentialEditBottomSheet(existing: existing),
    ),
  );
}

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
  bool _obscureToken = true;

  bool get _isEditing => widget.existing != null;

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
                      ? 'Edit GitHub Credential'
                      : 'Add GitHub Credential',
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
                  controller: _tokenController,
                  obscureText: _obscureToken,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Personal Access Token',
                    hintText: _isEditing
                        ? 'Leave blank to keep the current token'
                        : 'ghp_… or github_pat_…',
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
                  controller: _defaultOwnerController,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Default Org/Owner (optional)',
                    hintText: 'octocat',
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
                _TestGitHubConnectionStatus(state: testState),
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
        );
  }
}

class _TestGitHubConnectionStatus extends StatelessWidget {
  const _TestGitHubConnectionStatus({required this.state});

  final AsyncValue<String?> state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      AsyncData(value: null) => const SizedBox.shrink(),
      AsyncData(:final value?) => Text(
        'Connected — authenticated as $value',
        style: const TextStyle(color: Colors.green),
      ),
      AsyncLoading() => const Text('Testing...'),
      AsyncError(:final error) => Text(
        'Failed: ${describeError(error)}',
        style: const TextStyle(color: Colors.red),
      ),
    };
  }
}
