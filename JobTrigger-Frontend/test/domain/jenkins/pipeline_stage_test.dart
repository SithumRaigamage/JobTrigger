import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/pipeline_stage.dart';

PipelineStage _stage(String name, String status, int start, int duration) =>
    PipelineStage(
      id: name,
      name: name,
      status: status,
      startTimeMillis: start,
      durationMillis: duration,
    );

void main() {
  // The exact shape the fixture Jenkins returned for `pipeline-stages`
  // (P11-08): the parallel block is flattened, with no parent link.
  final fixtureShape = [
    _stage('Checkout', 'SUCCESS', 1000, 114),
    _stage('Build', 'SUCCESS', 1120, 71),
    _stage('Test', 'SUCCESS', 1200, 83),
    _stage('Unit', 'SUCCESS', 1283, 218),
    _stage('Integration', 'FAILED', 1305, 213),
    _stage('Deploy', 'FAILED', 1600, 88),
  ];

  test('folds overlapping stages into the preceding stage as branches', () {
    final nodes = groupParallelStages(fixtureShape);

    expect(nodes.map((n) => n.stage.name), [
      'Checkout',
      'Build',
      'Test',
      'Deploy',
    ]);
    final test = nodes[2];
    expect(test.branches.map((b) => b.name), ['Unit', 'Integration']);
  });

  test('a parallel parent shows the worst branch status', () {
    final test = groupParallelStages(fixtureShape)[2];
    // Jenkins reports the parent SUCCESS although Integration failed.
    expect(test.stage.status, 'SUCCESS');
    expect(test.status, 'FAILED');
  });

  test('sequential stages are never grouped', () {
    final nodes = groupParallelStages([
      _stage('A', 'SUCCESS', 0, 10),
      _stage('B', 'SUCCESS', 10, 10),
      _stage('C', 'SUCCESS', 20, 10),
    ]);
    expect(nodes.every((n) => n.branches.isEmpty), isTrue);
    expect(nodes, hasLength(3));
  });

  test('stages without timing are never grouped', () {
    final nodes = groupParallelStages(const [
      PipelineStage(id: 'a', name: 'A', status: 'SUCCESS'),
      PipelineStage(id: 'b', name: 'B', status: 'SUCCESS'),
      PipelineStage(id: 'c', name: 'C', status: 'SUCCESS'),
    ]);
    expect(nodes.every((n) => n.branches.isEmpty), isTrue);
  });
}
