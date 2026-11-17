import 'package:flutter/material.dart';

import '../../common_widgets/data_freshness.dart';

/// "Saved 2h ago · can't reach the server" (`US-SQ-OFFLINE-01`): shown above a
/// list that is the copy saved on the device because the server could not be
/// reached, so old data is never mistaken for current data.
///
/// PI-05: delegates to [DataFreshnessBanner] so the copy and styling live in
/// one shared place; the SonarQube style keeps the long-standing wording.
class SonarQubeSavedBanner extends StatelessWidget {
  const SonarQubeSavedBanner({required this.savedAt, super.key});

  final DateTime savedAt;

  @override
  Widget build(BuildContext context) {
    return DataFreshnessBanner(
      style: FreshnessStyle.sonarqube,
      savedAt: savedAt,
      offline: true,
    );
  }
}
