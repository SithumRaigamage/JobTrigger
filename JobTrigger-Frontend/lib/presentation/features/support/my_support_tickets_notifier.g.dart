// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_support_tickets_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// P25-05: the caller's own reports (`GET /api/support/tickets`), newest
/// first, so the Support screen can show whether an earlier report was seen.

@ProviderFor(MySupportTicketsNotifier)
final mySupportTicketsNotifierProvider = MySupportTicketsNotifierProvider._();

/// P25-05: the caller's own reports (`GET /api/support/tickets`), newest
/// first, so the Support screen can show whether an earlier report was seen.
final class MySupportTicketsNotifierProvider
    extends
        $AsyncNotifierProvider<MySupportTicketsNotifier, List<SupportTicket>> {
  /// P25-05: the caller's own reports (`GET /api/support/tickets`), newest
  /// first, so the Support screen can show whether an earlier report was seen.
  MySupportTicketsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mySupportTicketsNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mySupportTicketsNotifierHash();

  @$internal
  @override
  MySupportTicketsNotifier create() => MySupportTicketsNotifier();
}

String _$mySupportTicketsNotifierHash() =>
    r'ec26a373a003b8c5ad5e9177d17ba04d9adeb680';

/// P25-05: the caller's own reports (`GET /api/support/tickets`), newest
/// first, so the Support screen can show whether an earlier report was seen.

abstract class _$MySupportTicketsNotifier
    extends $AsyncNotifier<List<SupportTicket>> {
  FutureOr<List<SupportTicket>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<SupportTicket>>, List<SupportTicket>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<SupportTicket>>, List<SupportTicket>>,
              AsyncValue<List<SupportTicket>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
