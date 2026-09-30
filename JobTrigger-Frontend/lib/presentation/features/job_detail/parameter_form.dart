import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/jenkins/jenkins_build.dart';
import '../../../domain/jenkins/parameter_definition.dart';
import '../../../domain/jenkins/parameter_file.dart';
import '../../../domain/jenkins/parameter_values.dart';
import '../history/job_history_notifier.dart';
import '../settings/active_server_notifier.dart';

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
    this.files = const {},
    this.onPickFile,
    this.onRemoveFile,
  });

  final List<ParameterDefinition> parameters;
  final Map<String, String> values;
  final void Function(String name, String value) onChanged;

  /// Files chosen for file parameters (US-JX-02), by parameter name.
  final Map<String, ParameterFile> files;

  /// Null where uploads aren't supported (e.g. an input step), in which
  /// case a file parameter explains that instead of offering a picker.
  final void Function(String name)? onPickFile;
  final void Function(String name)? onRemoveFile;

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
      case textParameterType:
        return TextFormField(
          key: key,
          initialValue: value,
          minLines: 3,
          maxLines: 8,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            labelText: param.name,
            helperText: param.description,
            alignLabelWithHint: true,
          ),
          onChanged: report,
        );
      case runParameterType:
        return _RunParameterField(
          key: key,
          param: param,
          value: value,
          onChanged: report,
        );
      case credentialsParameterType:
        return TextFormField(
          key: key,
          initialValue: value,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: param.name,
            helperText: [
              if (param.description case final description?
                  when description.isNotEmpty)
                description,
              'Credentials ID, not a secret · blank uses the job default',
            ].join(' · '),
          ),
          onChanged: report,
        );
      case fileParameterType:
        return _FileParameterField(
          key: key,
          param: param,
          file: files[param.name],
          onPick: onPickFile == null ? null : () => onPickFile!(param.name),
          onRemove: onRemoveFile == null
              ? null
              : () => onRemoveFile!(param.name),
        );
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
      default: // StringParameterDefinition and plugin types.
        final known = knownParameterTypes.contains(param.type);
        final choices = param.choices;
        if (!known && choices != null && choices.isNotEmpty) {
          // A plugin type that declares choices still gets a dropdown.
          return _fieldFor(
            ParameterDefinition(
              name: param.name,
              type: 'ChoiceParameterDefinition',
              description: _unsupportedNote(param),
              choices: choices,
              defaultValue: param.defaultValue,
            ),
            value,
          );
        }
        return TextFormField(
          key: key,
          initialValue: value,
          decoration: InputDecoration(
            labelText: param.name,
            helperText: known ? param.description : _unsupportedNote(param),
          ),
          onChanged: report,
        );
    }
  }
}

/// Helper text for a parameter type this app has no purpose-built input for
/// (US-JX-02): the user must know the value is sent as plain text.
String _unsupportedNote(ParameterDefinition param) => [
  if (param.description case final description? when description.isNotEmpty)
    description,
  'Unsupported type (${param.type}) — value sent as text',
].join(' · ');

/// US-JX-02: a `RunParameterDefinition` picks one of its project's recent
/// builds. The default choice leaves the parameter blank, so it's omitted
/// and Jenkins uses its own default (the latest build). An empty value is
/// an HTTP 500 (AUD-38). If the build list can't load, the field falls back
/// to free text (`job#number`).
class _RunParameterField extends ConsumerWidget {
  const _RunParameterField({
    super.key,
    required this.param,
    required this.value,
    required this.onChanged,
  });

  final ParameterDefinition param;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectName = param.projectName;
    final baseUrl = ref.watch(
      activeServerNotifierProvider.select((server) => server?.jenkinsURL),
    );
    if (projectName == null || baseUrl == null) return _freeText();

    final history = ref.watch(
      jobHistoryNotifierProvider(jobUrlFromFullName(baseUrl, projectName)),
    );
    return history.when(
      data: (builds) => _picker(projectName, builds),
      loading: () => _picker(projectName, const [], loading: true),
      error: (_, _) => _freeText(),
    );
  }

  Widget _picker(
    String projectName,
    List<JenkinsBuild> builds, {
    bool loading = false,
  }) {
    final options = {
      '': loading ? 'Loading builds…' : 'Server default (latest build)',
      for (final build in builds)
        '$projectName#${build.number}':
            '#${build.number}${build.result == null ? '' : ' · ${build.result}'}',
    };
    return DropdownButtonFormField<String>(
      // Rebuilt once the build list arrives, so the selection is valid.
      key: ValueKey('run:${param.name}:${builds.length}'),
      initialValue: options.containsKey(value) ? value : '',
      decoration: InputDecoration(
        labelText: param.name,
        helperText: param.description ?? 'Build of $projectName',
      ),
      items: [
        for (final MapEntry(key: optionValue, value: label) in options.entries)
          DropdownMenuItem(value: optionValue, child: Text(label)),
      ],
      onChanged: loading
          ? null
          : (selected) {
              if (selected != null) onChanged(selected);
            },
    );
  }

  Widget _freeText() => TextFormField(
    initialValue: value,
    decoration: InputDecoration(
      labelText: param.name,
      helperText: 'job#number · blank uses the latest build',
    ),
    onChanged: onChanged,
  );
}

/// US-JX-02: a file parameter picks a local file, which is uploaded as a
/// multipart part named after the parameter. Files over
/// [maxParameterFileBytes] are refused before upload.
class _FileParameterField extends StatelessWidget {
  const _FileParameterField({
    super.key,
    required this.param,
    required this.file,
    required this.onPick,
    required this.onRemove,
  });

  final ParameterDefinition param;
  final ParameterFile? file;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chosen = file;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: param.name,
        helperText: onPick == null
            ? 'File upload isn\'t available here'
            : (param.description ?? 'Optional · up to 50 MB'),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_file, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              chosen == null
                  ? 'No file chosen'
                  : '${chosen.fileName} · ${formatFileSize(chosen.sizeBytes)}',
              style: textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chosen != null && onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Remove ${chosen.fileName}',
              onPressed: onRemove,
            ),
          if (onPick != null)
            TextButton(
              onPressed: onPick,
              child: Text(chosen == null ? 'Choose' : 'Replace'),
            ),
        ],
      ),
    );
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
