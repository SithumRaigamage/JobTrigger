import '../tool_selection/ci_tool.dart';

/// The tools this release offers, as "Jenkins, GitHub Actions and SonarQube",
/// or null when there is only one: with a single tool "together" would
/// promise something the release doesn't have (release/tools.json).
String? _releasedToolsTogether() {
  final names = [
    for (final tool in CiTool.values)
      if (tool.isAvailable) tool.displayName,
  ];
  if (names.length < 2) return null;
  return '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
}

/// P20-23: the paywall's headline matches what the user just tried
/// (`/paywall?reason=<limit>`, the backend's `limit` values and the app's
/// own gate names). Unknown or missing reasons get the general headline.
String paywallHeadline(String? reason) => switch (reason) {
  'maxCredentialsTotal' ||
  'maxCredentialsPerTool' => 'Add more servers with Pro',
  'multiTool' =>
    _releasedToolsTogether() == null
        ? 'Use more tools as they release'
        : 'Use ${_releasedToolsTogether()} together',
  'primaryCooldown' => 'Switch servers freely with Pro',
  'locked' => 'Use all your saved servers with Pro',
  'backgroundWatch' => 'Get notified when a build finishes',
  'homeWidget' => 'Put your jobs on the home screen',
  'maxPinnedJobs' => 'Pin as many jobs as you like',
  'insights' => 'See trends across your builds',
  _ => 'Get more from JobTrigger with Pro',
};

/// What Pro includes, in the order the paywall lists it. The tools line
/// follows the release: it names only the tools this build offers.
List<String> get proBenefits => [
  'Unlimited servers and accounts',
  _releasedToolsTogether() == null
      ? 'More tools together as they release'
      : '${_releasedToolsTogether()} together',
  'Build-finished notifications',
  'Home-screen widget',
  'Unlimited pinned jobs',
  'Build trends and insights',
];
