// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_form_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// P25-05: one in-flight submission. `null` means nothing sent yet; a value
/// is the ticket the backend stored; an error is what to show under the form.

@ProviderFor(SupportFormNotifier)
final supportFormNotifierProvider = SupportFormNotifierProvider._();

/// P25-05: one in-flight submission. `null` means nothing sent yet; a value
/// is the ticket the backend stored; an error is what to show under the form.
final class SupportFormNotifierProvider
    extends $AsyncNotifierProvider<SupportFormNotifier, SupportTicket?> {
  /// P25-05: one in-flight submission. `null` means nothing sent yet; a value
  /// is the ticket the backend stored; an error is what to show under the form.
  SupportFormNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supportFormNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supportFormNotifierHash();

  @$internal
  @override
  SupportFormNotifier create() => SupportFormNotifier();
}

String _$supportFormNotifierHash() =>
    r'66005354d96012678f4cb0b656a1db0954f26370';

/// P25-05: one in-flight submission. `null` means nothing sent yet; a value
/// is the ticket the backend stored; an error is what to show under the form.

abstract class _$SupportFormNotifier extends $AsyncNotifier<SupportTicket?> {
  FutureOr<SupportTicket?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SupportTicket?>, SupportTicket?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SupportTicket?>, SupportTicket?>,
              AsyncValue<SupportTicket?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
