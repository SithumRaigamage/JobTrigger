@Tags(['fixture'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';

import 'fixture_support.dart';

/// P11-20 / US-JX-12 against the real nodes: the built-in node and the
/// never-connecting `agent-1`.
void main() {
  // Lazy: `main()` still runs when the `fixture` tag is skipped.
  late final jenkins = FixtureJenkins.fromEnvironment();

  test('lists nodes and toggles one offline with a reason, and back', () async {
    final repository = jenkins.adminRepository();
    var nodes = expectOk(await repository.fetchNodes());
    final builtIn = nodes.singleWhere((node) => node.isBuiltIn);
    expect(builtIn.numExecutors, 4);
    expect(builtIn.offline, isFalse);

    final agent = nodes.singleWhere((node) => node.displayName == 'agent-1');
    expect(agent.offline, isTrue);
    expect(agent.temporarilyOffline, isFalse);

    expectOk(
      await repository.toggleNodeOffline(agent, message: 'fixture test'),
    );
    addTearDown(() async {
      final now = expectOk(await repository.fetchNodes());
      final current = now.singleWhere((node) => node.displayName == 'agent-1');
      if (current.temporarilyOffline) {
        await repository.toggleNodeOffline(current);
      }
    });

    nodes = expectOk(await repository.fetchNodes());
    final marked = nodes.singleWhere((node) => node.displayName == 'agent-1');
    expect(marked.temporarilyOffline, isTrue);
    expect(marked.offlineReason, 'fixture test');

    expectOk(await repository.toggleNodeOffline(marked));
    nodes = expectOk(await repository.fetchNodes());
    expect(
      nodes
          .singleWhere((node) => node.displayName == 'agent-1')
          .temporarilyOffline,
      isFalse,
    );
  });

  test('a read-only user cannot toggle a node', () async {
    final nodes = expectOk(await jenkins.adminRepository().fetchNodes());
    final agent = nodes.singleWhere((node) => node.displayName == 'agent-1');

    final result = await jenkins.viewerRepository().toggleNodeOffline(agent);
    expect((result as Err<void, AppFailure>).error, isA<PermissionFailure>());
  });
}
