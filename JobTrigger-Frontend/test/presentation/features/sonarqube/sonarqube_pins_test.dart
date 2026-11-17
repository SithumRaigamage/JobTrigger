import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/credentials/active_sonarqube_credential_notifier.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_overview.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project_summary.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_quality_gate.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_pins_notifier.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_project_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Credential extends ActiveSonarQubeCredentialNotifier {
  _Credential(this.id);
  final String id;
  @override
  SonarQubeCredential? build() =>
      SonarQubeCredential(id: id, label: 'L', baseUrl: 'http://s', secret: 't');
}

const _a = SonarQubeProject(key: 'a', name: 'Alpha', lastAnalysisDate: null);
const _b = SonarQubeProject(key: 'b', name: 'Beta', lastAnalysisDate: null);

ProviderContainer _container(String credentialId) {
  final c = ProviderContainer(
    overrides: [
      activeSonarQubeCredentialNotifierProvider.overrideWith(
        () => _Credential(credentialId),
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('pins are remembered per credential (US-SQ-PIN-01)', () async {
    SharedPreferences.setMockInitialValues({});
    final first = _container('c1');
    first.listen(sonarQubePinsNotifierProvider, (_, _) {});
    final notifier = first.read(sonarQubePinsNotifierProvider.notifier);

    expect(await notifier.toggle(_a), isTrue);
    expect(await notifier.toggle(_b), isTrue);
    expect(first.read(sonarQubePinnedKeysProvider), {'a', 'b'});
    expect(await notifier.toggle(_a), isFalse);
    expect(first.read(sonarQubePinnedKeysProvider), {'b'});

    // A new session for the same credential loads them again.
    final again = _container('c1');
    again.listen(sonarQubePinsNotifierProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(again.read(sonarQubePinnedKeysProvider), {'b'});

    // Another credential has its own list.
    final other = _container('c2');
    other.listen(sonarQubePinsNotifierProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(other.read(sonarQubePinnedKeysProvider), isEmpty);
  });

  test('pinned failing projects are listed first in the overview', () {
    const failed = SonarQubeProjectSummary(gate: QualityGateState.failed);
    final summaries = {'a': failed, 'b': failed};
    final overview = buildSonarQubeOverview([_a, _b], summaries, pinned: {'b'});
    expect(overview.needsAttention.map((p) => p.key), ['b', 'a']);
  });

  testWidgets('the card pins and unpins, and says which', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeSonarQubeCredentialNotifierProvider.overrideWith(
            () => _Credential('c1'),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: SonarQubePinButton(project: _a)),
        ),
      ),
    );
    expect(find.byTooltip('Pin Alpha'), findsOneWidget);
    await tester.tap(find.byTooltip('Pin Alpha'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Unpin Alpha'), findsOneWidget);
    await tester.tap(find.byTooltip('Unpin Alpha'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Pin Alpha'), findsOneWidget);
  });
}
