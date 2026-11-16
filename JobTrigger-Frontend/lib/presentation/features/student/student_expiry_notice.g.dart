// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_expiry_notice.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Phase 21 (SP-60): when the free student year ends within 7 days, the end
/// date; otherwise null. Only where billing is available, so a default build
/// and demo mode never see it. Computed from the plan the app already has.

@ProviderFor(studentExpiryNotice)
final studentExpiryNoticeProvider = StudentExpiryNoticeProvider._();

/// Phase 21 (SP-60): when the free student year ends within 7 days, the end
/// date; otherwise null. Only where billing is available, so a default build
/// and demo mode never see it. Computed from the plan the app already has.

final class StudentExpiryNoticeProvider
    extends $FunctionalProvider<DateTime?, DateTime?, DateTime?>
    with $Provider<DateTime?> {
  /// Phase 21 (SP-60): when the free student year ends within 7 days, the end
  /// date; otherwise null. Only where billing is available, so a default build
  /// and demo mode never see it. Computed from the plan the app already has.
  StudentExpiryNoticeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'studentExpiryNoticeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$studentExpiryNoticeHash();

  @$internal
  @override
  $ProviderElement<DateTime?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DateTime? create(Ref ref) {
    return studentExpiryNotice(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime?>(value),
    );
  }
}

String _$studentExpiryNoticeHash() =>
    r'0c6b9054654d7d93b4fc1790851fdd1a60cb33c2';
