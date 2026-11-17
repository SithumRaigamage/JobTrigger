import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_language_breakdown.dart';

void main() {
  group('language breakdown (US-SQ-QUALITY-13)', () {
    test('splits the metric, biggest first, with shares', () {
      final breakdown = SonarQubeLanguageBreakdown.parse(
        'java=1200;js=340;css=60',
      );

      expect(breakdown.languages.map((l) => l.language), ['java', 'js', 'css']);
      expect(breakdown.languages.map((l) => l.lines), [1200, 340, 60]);
      expect(breakdown.languages.first.share, 75);
      expect(breakdown.languages.fold<int>(0, (sum, l) => sum + l.share), 100);
    });

    test('equal counts are ordered by name, so the list is stable', () {
      final breakdown = SonarQubeLanguageBreakdown.parse('js=10;java=10');

      expect(breakdown.languages.map((l) => l.language), ['java', 'js']);
    });

    test('skips fragments that are not a name and a positive count', () {
      final breakdown = SonarQubeLanguageBreakdown.parse(
        'java=100; broken; =50; js=; css=-4; py=abc; go=25',
      );

      expect(breakdown.languages.map((l) => l.language), ['java', 'go']);
      expect(breakdown.languages.last.share, 20);
    });

    test('nothing to show is empty, not an error', () {
      expect(SonarQubeLanguageBreakdown.parse(null).isEmpty, isTrue);
      expect(SonarQubeLanguageBreakdown.parse('').isEmpty, isTrue);
      expect(SonarQubeLanguageBreakdown.parse('java=0').isEmpty, isTrue);
      expect(SonarQubeLanguageBreakdown.parse(';;').isEmpty, isTrue);
    });
  });
}
