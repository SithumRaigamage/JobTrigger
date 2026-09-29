import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'parameter_edits_notifier.g.dart';

/// The user's edits to one parameter form, keyed by [formKey]: the job URL
/// for the trigger form, `replay:<buildUrl>` for replay, and
/// `input:<buildUrl>#<inputId>` for an input step.
///
/// Stores **only edits**, never defaults. What a form shows is
/// `effectiveParameterValues(definitions, edits)`, so:
/// - a field scrolled off-screen and rebuilt keeps its value (AUD-18),
///   because it re-reads from here instead of re-seeding local `State`;
/// - the 5s poll re-fetching the job never resets what the user typed,
///   because nothing here is recomputed from the fetch.
///
/// Auto-disposed with the screen or sheet that watches it, so edits
/// don't outlive the form.
@riverpod
class ParameterEditsNotifier extends _$ParameterEditsNotifier {
  @override
  Map<String, String> build(String formKey) => const {};

  void setValue(String name, String value) => state = {...state, name: value};

  void clear() => state = const {};
}
