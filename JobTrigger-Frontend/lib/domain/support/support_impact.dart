/// P31-02: how badly a report affects the user. Single select; the backend
/// defaults to [minor] when an older client omits it.
enum SupportImpact {
  blocked('blocked', 'Blocked'),
  major('major', 'Major'),
  minor('minor', 'Minor');

  const SupportImpact(this.wire, this.label);

  final String wire;
  final String label;

  static SupportImpact fromWire(String? wire) => switch (wire) {
    'blocked' => SupportImpact.blocked,
    'major' => SupportImpact.major,
    _ => SupportImpact.minor,
  };
}
