/// PI-08 / IMP-74: the three milestones shown in Home's first-run card.
///
/// Pure so the card and its tests agree on what "done" means: a connected
/// tool, a build the user triggered, and at least one active watch.
class FirstRunSteps {
  const FirstRunSteps({
    required this.connected,
    required this.triggered,
    required this.alerts,
  });

  /// At least one tool has a saved credential.
  final bool connected;

  /// The user triggered a build or workflow from this app.
  final bool triggered;

  /// At least one build or project is watched for notifications.
  final bool alerts;

  /// Everything is done, so the card can retire itself.
  bool get allDone => connected && triggered && alerts;

  /// How many of the three steps are done, for the progress line.
  int get doneCount =>
      [connected, triggered, alerts].where((done) => done).length;
}
