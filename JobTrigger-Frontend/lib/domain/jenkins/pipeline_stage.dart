/// One stage of a pipeline run, from `{buildURL}wfapi/describe` (US-PIPE-04).
///
/// [status] uses Jenkins' pipeline vocabulary: `SUCCESS`, `FAILED`,
/// `UNSTABLE`, `IN_PROGRESS`, `PAUSED_PENDING_INPUT`, `NOT_EXECUTED`,
/// `ABORTED`. That differs from a build's `result`.
class PipelineStage {
  const PipelineStage({
    required this.id,
    required this.name,
    required this.status,
    this.durationMillis,
    this.startTimeMillis,
    this.errorMessage,
  });

  /// Flow-node id, used for `execution/node/{id}/…` (US-JX-04).
  final String id;
  final String name;
  final String status;
  final int? durationMillis;
  final int? startTimeMillis;

  /// Why the stage failed, when Jenkins reports it (`error.message`).
  final String? errorMessage;

  bool get isFailed => status.toUpperCase() == 'FAILED';
}

/// A stage together with the parallel branches it fans out into, if any.
class StageNode {
  const StageNode(this.stage, [this.branches = const []]);

  final PipelineStage stage;
  final List<PipelineStage> branches;

  /// The status to show for the whole group. Jenkins reports a parallel
  /// parent as `SUCCESS` even when one of its branches failed (verified on
  /// the fixture), so a failed, unstable, or running branch wins.
  String get status {
    for (final worst in const ['FAILED', 'UNSTABLE', 'IN_PROGRESS']) {
      if (branches.any((branch) => branch.status.toUpperCase() == worst)) {
        return worst;
      }
    }
    return stage.status;
  }
}

/// Groups parallel branches under their parent stage (US-JX-04).
///
/// The Pipeline REST API flattens a `parallel` block into the stage list
/// with no parent link: `Test` (no steps of its own) followed by `Unit` and
/// `Integration`, verified on the fixture Jenkins. The only signal is time.
/// A run of two or more consecutive stages whose time ranges overlap are
/// parallel branches, and belong to the stage immediately before them.
/// Stages without timing are never grouped.
List<StageNode> groupParallelStages(List<PipelineStage> stages) {
  bool overlaps(PipelineStage a, PipelineStage b) {
    final aStart = a.startTimeMillis;
    final bStart = b.startTimeMillis;
    if (aStart == null || bStart == null) return false;
    final aEnd = aStart + (a.durationMillis ?? 0);
    final bEnd = bStart + (b.durationMillis ?? 0);
    return aStart < bEnd && bStart < aEnd;
  }

  final nodes = <StageNode>[];
  var index = 0;
  while (index < stages.length) {
    final parent = stages[index];
    final first = index + 1;
    if (first + 1 < stages.length &&
        overlaps(stages[first], stages[first + 1])) {
      // Branches start together, so each one overlaps the first branch.
      var last = first + 1;
      while (last + 1 < stages.length &&
          overlaps(stages[first], stages[last + 1])) {
        last++;
      }
      nodes.add(StageNode(parent, stages.sublist(first, last + 1)));
      index = last + 1;
    } else {
      nodes.add(StageNode(parent));
      index++;
    }
  }
  return nodes;
}

/// One step inside a stage (`execution/node/{stageId}/wfapi/describe`'s
/// `stageFlowNodes`), e.g. "Print Message" or "Shell Script" (US-JX-04).
class PipelineStep {
  const PipelineStep({
    required this.id,
    required this.name,
    required this.status,
    this.description,
    this.durationMillis,
  });

  final String id;
  final String name;
  final String status;

  /// Jenkins' `parameterDescription`: the command or message, e.g. the
  /// shell line or the error text.
  final String? description;
  final int? durationMillis;

  bool get isFailed => status.toUpperCase() == 'FAILED';
  bool get isRunning => status.toUpperCase() == 'IN_PROGRESS';
}

/// A step's log (`execution/node/{stepId}/wfapi/log`). [hasMore] means
/// Jenkins truncated it; the full console has the rest.
class StepLog {
  const StepLog({required this.text, required this.hasMore});

  final String text;
  final bool hasMore;
}
