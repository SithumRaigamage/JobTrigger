/// PI-10 / IMP-65: the in-app "What's new" copy, kept next to the app
/// version it describes. A release that ships user-visible changes adds an
/// entry here; the app shows it once per install, on first launch after the
/// update.
class WhatsNewRelease {
  const WhatsNewRelease({required this.version, required this.items});

  /// The major.minor the items belong to, e.g. `1.0`.
  final String version;
  final List<String> items;
}

const whatsNewReleases = [
  WhatsNewRelease(
    version: '1.0',
    items: [
      'Jenkins, GitHub Actions and SonarQube in one app.',
      'Trigger builds and workflows with every parameter they take.',
      'Live logs, stages, tests and history for every run.',
      'Notifications with rules — failures only, or back to green.',
      'Pinned jobs, saved views, the build queue and nodes.',
      'Students get JobTrigger Pro free for one year: verify with a university email or a student ID.',
      'Offline-aware screens that say how old their data is.',
      'Read-only server mode and a confirmation step for protected actions.',
      'Replay a pipeline build with an edited script (inline pipeline jobs).',
      'Pair a server from the JobTrigger website with a QR code.',
      'Send a redacted support report and track its status in the app.',
      'Switch servers from any tool screen without losing your place.',
      'Subscribe to Pro in the app or on the website; promo codes add free Pro time.',
      'Student applications are approved by hand after the email is verified.',
      'Personal data is encrypted at rest; admin search is exact-email only.',
      'App lock and local build alerts; push notifications are not included.',
    ],
  ),
];

/// The release notes for [version], or null when this version has none.
/// `1.0.0` and `1.0.1` both match the `1.0` entry.
WhatsNewRelease? whatsNewFor(String version) {
  final short = version.split('.').take(2).join('.');
  for (final release in whatsNewReleases) {
    if (release.version == short) return release;
  }
  return null;
}
