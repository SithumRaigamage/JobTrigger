import 'package:flutter/material.dart';

import '../../../domain/jenkins/parameter_definition.dart';
import '../../../domain/jenkins/parameter_values.dart';

/// Renders one input per [ParameterDefinition], switching on its `type`
/// (ported from `JobDetailView`, extended for US-JX-01).
///
/// Holds no values of its own: [values] come from the caller (a
/// `ParameterEditsNotifier` via `effectiveParameterValues`), and every edit
/// is reported through [onChanged]. A field that's scrolled away and
/// rebuilt therefore shows what the user typed, not the default again
/// (AUD-18).
class ParameterForm extends StatelessWidget {
  const ParameterForm({
    super.key,
    required this.parameters,
    required this.values,
    required this.onChanged,
  });

  final List<ParameterDefinition> parameters;
  final Map<String, String> values;
  final void Function(String name, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final param in parameters) ...[
          _fieldFor(param, values[param.name] ?? ''),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _fieldFor(ParameterDefinition param, String value) {
    // Keyed by type+name so a field is never reused for a different
    // parameter when the list changes (e.g. after a job refresh).
    final key = ValueKey('${param.type}:${param.name}');
    void report(String newValue) => onChanged(param.name, newValue);

    if (isSecretParameter(param)) {
      return _SecretParameterField(
        key: key,
        param: param,
        value: value,
        onChanged: report,
      );
    }

    switch (param.type) {
      case 'BooleanParameterDefinition':
        return SwitchListTile(
          key: key,
          contentPadding: EdgeInsets.zero,
          title: Text(param.name),
          subtitle: param.description == null ? null : Text(param.description!),
          value: value == 'true',
          onChanged: (checked) => report(checked.toString()),
        );
      case 'ChoiceParameterDefinition':
        final choices = param.choices ?? const <String>[];
        return DropdownButtonFormField<String>(
          key: key,
          // A value outside the declared choices (e.g. a replayed value the
          // job has since removed) would trip the dropdown's assertion;
          // show no selection instead.
          initialValue: choices.contains(value) ? value : null,
          decoration: InputDecoration(
            labelText: param.name,
            helperText: param.description,
          ),
          items: [
            for (final choice in choices)
              DropdownMenuItem(value: choice, child: Text(choice)),
          ],
          onChanged: (selected) {
            if (selected != null) report(selected);
          },
        );
      default: // StringParameterDefinition and anything unrecognized.
        return TextFormField(
          key: key,
          initialValue: value,
          decoration: InputDecoration(
            labelText: param.name,
            helperText: param.description,
          ),
          onChanged: report,
        );
    }
  }
}

/// US-JX-01: masked, never pre-filled, with no autocorrect, suggestions,
/// or autofill. Left blank, the parameter is omitted from the trigger so
/// Jenkins applies its stored default (`triggerParameters`).
class _SecretParameterField extends StatefulWidget {
  const _SecretParameterField({
    super.key,
    required this.param,
    required this.value,
    required this.onChanged,
  });

  final ParameterDefinition param;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_SecretParameterField> createState() => _SecretParameterFieldState();
}

class _SecretParameterFieldState extends State<_SecretParameterField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final description = widget.param.description;
    return TextFormField(
      initialValue: widget.value,
      obscureText: _obscured,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.visiblePassword,
      decoration: InputDecoration(
        labelText: widget.param.name,
        helperText: [
          if (description != null && description.isNotEmpty) description,
          'Leave blank to use the server default',
        ].join(' · '),
        suffixIcon: IconButton(
          icon: Icon(_obscured ? Icons.visibility : Icons.visibility_off),
          tooltip: _obscured
              ? 'Show ${widget.param.name}'
              : 'Hide ${widget.param.name}',
          onPressed: () => setState(() => _obscured = !_obscured),
        ),
      ),
      onChanged: widget.onChanged,
    );
  }
}
