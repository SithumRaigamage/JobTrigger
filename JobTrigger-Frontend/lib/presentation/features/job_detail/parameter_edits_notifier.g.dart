// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parameter_edits_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(ParameterEditsNotifier)
final parameterEditsNotifierProvider = ParameterEditsNotifierFamily._();

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
final class ParameterEditsNotifierProvider
    extends $NotifierProvider<ParameterEditsNotifier, Map<String, String>> {
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
  ParameterEditsNotifierProvider._({
    required ParameterEditsNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'parameterEditsNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$parameterEditsNotifierHash();

  @override
  String toString() {
    return r'parameterEditsNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ParameterEditsNotifier create() => ParameterEditsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, String>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ParameterEditsNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$parameterEditsNotifierHash() =>
    r'7927a81b61574a27db9c369b5e20eede04e3e534';

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

final class ParameterEditsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ParameterEditsNotifier,
          Map<String, String>,
          Map<String, String>,
          Map<String, String>,
          String
        > {
  ParameterEditsNotifierFamily._()
    : super(
        retry: null,
        name: r'parameterEditsNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

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

  ParameterEditsNotifierProvider call(String formKey) =>
      ParameterEditsNotifierProvider._(argument: formKey, from: this);

  @override
  String toString() => r'parameterEditsNotifierProvider';
}

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

abstract class _$ParameterEditsNotifier extends $Notifier<Map<String, String>> {
  late final _$args = ref.$arg as String;
  String get formKey => _$args;

  Map<String, String> build(String formKey);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Map<String, String>, Map<String, String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, String>, Map<String, String>>,
              Map<String, String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
