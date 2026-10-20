import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/history_filter.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';

JenkinsBuild _build(
  int number,
  String? result, {
  bool building = false,
  List<String> by = const [],
}) => JenkinsBuild(
  number: number,
  url: 'u$number',
  result: result,
  timestamp: 0,
  building: building,
  startedByUserIds: by,
);

void main() {
  final builds = [
    _build(6, null, building: true, by: ['alice']),
    _build(5, 'FAILURE', by: ['alice']),
    _build(4, 'SUCCESS', by: ['bob']),
    _build(3, 'UNSTABLE'),
    _build(2, 'ABORTED', by: ['alice']),
    _build(1, 'FAILURE'),
  ];

  List<int> numbers(HistoryFilter filter, {String? username}) => [
    for (final build in filterHistory(builds, filter, username: username))
      build.number,
  ];

  test('result filters', () {
    expect(numbers(const HistoryFilter()), [6, 5, 4, 3, 2, 1]);
    expect(numbers(const HistoryFilter(result: HistoryResultFilter.failed)), [
      5,
      1,
    ]);
    expect(numbers(const HistoryFilter(result: HistoryResultFilter.running)), [
      6,
    ]);
    expect(numbers(const HistoryFilter(result: HistoryResultFilter.unstable)), [
      3,
    ]);
  });

  test('started by me combines with the result filter', () {
    const mine = HistoryFilter(startedByMe: true);
    expect(numbers(mine, username: 'alice'), [6, 5, 2]);
    expect(
      numbers(
        mine.copyWith(result: HistoryResultFilter.failed),
        username: 'alice',
      ),
      [5],
    );
    // No known user: nothing can be "mine".
    expect(numbers(mine), isEmpty);
  });

  test('folderPathOf', () {
    expect(folderPathOf('https://ci.test/job/api/'), '');
    expect(
      folderPathOf('https://ci.test/job/team/job/api/job/feature%2Flogin/'),
      'team / api',
    );
    expect(
      folderPathOf('https://ci.test/jenkins/job/a/job/b/'),
      'a',
      reason: 'a context path before /job/ is ignored',
    );
  });
}
