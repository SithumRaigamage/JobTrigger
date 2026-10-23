import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// A form field with its label above it, as the redesign draws every form
/// (`UI-UX/screens/01-login`, `21-edit-server-sheet`). The visible label is
/// also the field's accessible name: it's hidden from the semantics tree
/// where it's drawn and given to the field itself, so a screen reader
/// announces "Email, text field" rather than the label and the field as
/// two unrelated nodes.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.helper,
    this.monospaceLabel = false,
  });

  final String label;

  /// The field: a `TextField`, `TextFormField`, dropdown or similar.
  final Widget child;

  /// Optional line under the field (a hint or rule). Error text belongs on
  /// the field's own `InputDecoration.errorText` so it's announced with it.
  final String? helper;

  /// Jenkins parameter names are shown as written, in the monospaced face.
  final bool monospaceLabel;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final base = textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: t.textSecondary,
    );
    final labelStyle = monospaceLabel ? AppTypography.mono(base) : base;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: Text(label, style: labelStyle)),
        const SizedBox(height: 8),
        Semantics(label: label, child: child),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(helper!, style: textTheme.bodySmall),
        ],
      ],
    );
  }
}
