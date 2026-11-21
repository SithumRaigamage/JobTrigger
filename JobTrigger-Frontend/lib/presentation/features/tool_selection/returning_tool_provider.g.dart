// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'returning_tool_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-TOOL-01 (owner decision 2026-11-21): the tool a returning user goes
/// straight to, or null to show tool selection. A returning user is one
/// with at least one saved credential, of any tool. The tool chosen last
/// wins if it still has one (or if the lists can't be read); otherwise the
/// first tool, in the picker's order, that has one. A tool the plan locks
/// (P20-25) is never picked.

@ProviderFor(returningTool)
final returningToolProvider = ReturningToolProvider._();

/// US-TOOL-01 (owner decision 2026-11-21): the tool a returning user goes
/// straight to, or null to show tool selection. A returning user is one
/// with at least one saved credential, of any tool. The tool chosen last
/// wins if it still has one (or if the lists can't be read); otherwise the
/// first tool, in the picker's order, that has one. A tool the plan locks
/// (P20-25) is never picked.

final class ReturningToolProvider
    extends $FunctionalProvider<AsyncValue<CiTool?>, CiTool?, FutureOr<CiTool?>>
    with $FutureModifier<CiTool?>, $FutureProvider<CiTool?> {
  /// US-TOOL-01 (owner decision 2026-11-21): the tool a returning user goes
  /// straight to, or null to show tool selection. A returning user is one
  /// with at least one saved credential, of any tool. The tool chosen last
  /// wins if it still has one (or if the lists can't be read); otherwise the
  /// first tool, in the picker's order, that has one. A tool the plan locks
  /// (P20-25) is never picked.
  ReturningToolProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'returningToolProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$returningToolHash();

  @$internal
  @override
  $FutureProviderElement<CiTool?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<CiTool?> create(Ref ref) {
    return returningTool(ref);
  }
}

String _$returningToolHash() => r'0381552759e10efa90c81fe2e1267c0588ccb7a5';
