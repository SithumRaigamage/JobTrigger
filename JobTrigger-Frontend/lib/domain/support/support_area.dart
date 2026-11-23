/// P31-02: which part of JobTrigger a report concerns. Optional and
/// multi-select; [wire] is the backend's enum value and [label] is the chip.
enum SupportArea {
  jenkins('jenkins', 'Jenkins'),
  github('github', 'GitHub Actions'),
  sonarqube('sonarqube', 'SonarQube'),
  website('website', 'Website'),
  phone('phone', 'Phone/app'),
  account('account', 'Account');

  const SupportArea(this.wire, this.label);

  final String wire;
  final String label;

  static SupportArea? fromWire(String? wire) => switch (wire) {
    'jenkins' => SupportArea.jenkins,
    'github' => SupportArea.github,
    'sonarqube' => SupportArea.sonarqube,
    'website' => SupportArea.website,
    'phone' => SupportArea.phone,
    'account' => SupportArea.account,
    _ => null,
  };
}
