import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_message.dart';
import '../../../domain/credential/jenkins_server.dart';
import '../../common_widgets/toast_controller.dart';
import 'server_form_notifier.dart';
import 'test_connection_notifier.dart';

/// Ported from the add/edit sheet in `SettingsView.swift`. [existing] is
/// null when adding a new server, non-null when editing one.
Future<void> showServerEditBottomSheet(
  BuildContext context, {
  JenkinsServer? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => ServerEditBottomSheet(existing: existing),
  );
}

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

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Edit Server' : 'Add Server',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _serverNameController,
              decoration: const InputDecoration(
                labelText: 'Server Name',
                hintText: 'My Jenkins Server',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _jenkinsURLController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Jenkins URL',
                hintText: 'http://localhost:8080',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _usernameController,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _paramTokenController,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Build Token (for triggering)',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Set as default server'),
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value),
            ),
            const SizedBox(height: 8),
            _TestConnectionStatus(state: testState),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.wifi_tethering),
              label: const Text('Test Jenkins Connection'),
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
        );
  }
}

class _TestConnectionStatus extends StatelessWidget {
  const _TestConnectionStatus({required this.state});

  final AsyncValue<int?> state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      AsyncData(value: null) => const SizedBox.shrink(),
      AsyncData(:final value?) => Text(
        'Connected — $value job${value == 1 ? '' : 's'} found',
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
