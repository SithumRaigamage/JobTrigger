import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_tokens.dart';

/// Shows a credential edit sheet (`UI-UX/screens/21-edit-server-sheet`):
/// a bottom sheet on a phone, a centered dialog on a wide window.
///
/// Completes with `true` when the user asked to delete the item from inside
/// the sheet; the caller confirms and deletes, as it does for a swipe.
///
/// `useRootNavigator: true`: Settings lives inside `MainScaffold`'s
/// `StatefulShellRoute` branch — without it the sheet attaches to that
/// branch's own nested Navigator and renders underneath the persistent nav
/// bar, which cut it off and swallowed taps in the overlap.
Future<bool?> showEditSheet(BuildContext context, Widget sheet) {
  const wideBreakpoint = 900.0;
  if (MediaQuery.sizeOf(context).width >= wideBreakpoint) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        backgroundColor: AppTokens.of(context).card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: sheet,
        ),
      ),
    );
  }
  return showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    // Leaves a strip of the dimmed screen above, so it reads as a sheet
    // over Settings rather than a new page.
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.92,
    ),
    builder: (context) => sheet,
  );
}

/// The sheet's body: header, scrolling fields, and an optional destructive
/// action at the foot. Keeps the fields above the keyboard.
class EditSheetFrame extends StatelessWidget {
  const EditSheetFrame({
    super.key,
    required this.title,
    required this.saveLabel,
    required this.saving,
    required this.onSave,
    required this.children,
    this.deleteLabel,
  });

  final String title;
  final String saveLabel;
  final bool saving;
  final VoidCallback onSave;
  final List<Widget> children;

  /// "Delete server" etc.; null when adding, where there's nothing to delete.
  final String? deleteLabel;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: saving ? null : onSave,
                    child: saving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            saveLabel,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...children,
                    if (deleteLabel != null) ...[
                      const SizedBox(height: 24),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: t.failure.foreground,
                          minimumSize: const Size(64, 48),
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(deleteLabel!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Test connection" and, under it, what the last test found.
class ConnectionTest<T> extends StatelessWidget {
  const ConnectionTest({
    super.key,
    required this.state,
    required this.onTest,
    required this.describe,
  });

  final AsyncValue<T?> state;
  final VoidCallback onTest;

  /// The success line, e.g. "Connected — 17 jobs found".
  final String Function(T value) describe;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final testing = state.isLoading;
    final (IconData, Color, String)? result = switch (state) {
      AsyncLoading() => null,
      AsyncError(:final error) => (
        Icons.error_outline_rounded,
        t.failure.foreground,
        'Failed: ${describeError(error)}',
      ),
      AsyncData(:final value?) => (
        Icons.check_rounded,
        t.success.foreground,
        describe(value),
      ),
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.tonalIcon(
          style: FilledButton.styleFrom(
            backgroundColor: t.raised,
            foregroundColor: t.text,
          ),
          icon: const Icon(Icons.network_check_rounded, size: 20),
          label: Text(testing ? 'Testing…' : 'Test connection'),
          onPressed: testing ? null : onTest,
        ),
        if (result case (final icon, final color, final message))
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(child: Icon(icon, size: 20, color: color)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message,
                      style: textTheme.bodyMedium?.copyWith(color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A token or password field with a show/hide toggle. Never autocorrected
/// or suggested, so the secret doesn't land in the keyboard's dictionary.
class SecretTextField extends StatefulWidget {
  const SecretTextField({
    super.key,
    required this.controller,
    required this.noun,
    this.hintText,
    this.onChanged,
  });

  final TextEditingController controller;

  /// What the toggle reveals: "token", "password", "build token".
  final String noun;
  final String? hintText;
  final ValueChanged<String>? onChanged;

  @override
  State<SecretTextField> createState() => _SecretTextFieldState();
}

class _SecretTextFieldState extends State<SecretTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hintText,
        suffixIcon: IconButton(
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          tooltip: _obscure ? 'Show ${widget.noun}' : 'Hide ${widget.noun}',
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
