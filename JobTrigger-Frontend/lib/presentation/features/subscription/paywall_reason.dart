/// P20-23: the paywall's headline matches what the user just tried
/// (`/paywall?reason=<limit>`, the backend's `limit` values and the app's
/// own gate names). Unknown or missing reasons get the general headline.
String paywallHeadline(String? reason) => switch (reason) {
  'maxCredentialsTotal' ||
  'maxCredentialsPerTool' => 'Add more servers with Pro',
  'multiTool' => 'Use Jenkins, GitHub Actions and SonarQube together',
  'primaryCooldown' => 'Switch servers freely with Pro',
  'backgroundWatch' => 'Get notified when a build finishes',
  'homeWidget' => 'Put your jobs on the home screen',
  'maxPinnedJobs' => 'Pin as many jobs as you like',
  'insights' => 'See trends across your builds',
  _ => 'Get more from JobTrigger with Pro',
};

/// What Pro includes, in the order the paywall lists it.
const proBenefits = [
  'Unlimited servers and accounts',
  'Jenkins, GitHub Actions and SonarQube together',
  'Build-finished notifications',
  'Home-screen widget',
  'Unlimited pinned jobs',
  'Build trends and insights',
];
