import 'package:flutter/material.dart';

import '../../../domain/jenkins/parameter_definition.dart';

/// Switches on [ParameterDefinition.type], ported from
/// `JobDetailView`/`JobDetailViewModel.initializeParameters` (Swift).
/// Reports the current values (always stringified, per
/// `docs/data-models.md`) via [onChanged] on every edit and once
/// immediately after the first frame with initial defaults.
class ParameterForm extends StatefulWidget {
  const ParameterForm({
    super.key,
    required this.parameters,
    required this.onChanged,
  });

  final List<ParameterDefinition> parameters;
  final ValueChanged<Map<String, String>> onChanged;

  @override
  State<ParameterForm> createState() => _ParameterFormState();
}

class _ParameterFormState extends State<ParameterForm> {
  late final Map<String, String> _values = {
    for (final param in widget.parameters) param.name: _initialValueFor(param),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.onChanged(_values),
    );
  }

  /// Ported from `ParameterDefinition.defaultValue` (Swift): the declared
  /// default if present, else the first choice for choice parameters
  /// (Jenkins doesn't always send an explicit default for those), else
  /// empty.
  String _initialValueFor(ParameterDefinition param) {
    final declared = param.defaultValue;
    if (declared != null) return declared.toString();
    final choices = param.choices;
    if (choices != null && choices.isNotEmpty) return choices.first;
    return '';
  }

  void _update(String name, String value) {
    setState(() => _values[name] = value);
    widget.onChanged(_values);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final param in widget.parameters) ...[
          _fieldFor(param),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _fieldFor(ParameterDefinition param) {
    switch (param.type) {
      case 'BooleanParameterDefinition':
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(param.name),
          subtitle: param.description == null ? null : Text(param.description!),
          value: _values[param.name] == 'true',
          onChanged: (value) => _update(param.name, value.toString()),
        );
      case 'ChoiceParameterDefinition':
        return DropdownButtonFormField<String>(
          initialValue: _values[param.name],
          decoration: InputDecoration(
            labelText: param.name,
            helperText: param.description,
          ),
          items: [
            for (final choice in param.choices ?? const <String>[])
              DropdownMenuItem(value: choice, child: Text(choice)),
          ],
          onChanged: (value) {
            if (value != null) _update(param.name, value);
          },
        );
      default: // StringParameterDefinition and anything unrecognized.
        return TextFormField(
          initialValue: _values[param.name],
          decoration: InputDecoration(
            labelText: param.name,
            helperText: param.description,
          ),
          onChanged: (value) => _update(param.name, value),
        );
    }
  }
}
