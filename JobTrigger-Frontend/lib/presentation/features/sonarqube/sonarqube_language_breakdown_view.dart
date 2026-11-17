import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../domain/sonarqube/sonarqube_language_breakdown.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/section_label.dart';

/// `US-SQ-QUALITY-13`: the project's lines by language, as bars with the
/// lines and the share written out (readable without colour). Left out
/// entirely when the server reports no distribution.
class SonarQubeLanguageBreakdownView extends StatelessWidget {
  const SonarQubeLanguageBreakdownView({required this.measures, super.key});

  final Map<String, String> measures;

  @override
  Widget build(BuildContext context) {
    final breakdown = SonarQubeLanguageBreakdown.parse(
      measures[sonarQubeLanguageMetricKey],
    );
    if (breakdown.isEmpty) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        const SectionLabel('Languages'),
        const SizedBox(height: 10),
        GlassSurface.card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, language) in breakdown.languages.indexed) ...[
                if (index > 0) const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        language.language,
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${language.lines} lines · ${language.share}%',
                      style: textTheme.bodySmall?.copyWith(color: t.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: language.share / 100,
                    minHeight: 6,
                    backgroundColor: t.textMuted.withValues(alpha: 0.15),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
