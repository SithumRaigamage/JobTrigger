import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/server_status.dart';

void main() {
  test('compares dotted versions numerically', () {
    expect(compareJenkinsVersions('2.568.3', '2.516.1'), greaterThan(0));
    expect(compareJenkinsVersions('2.99', '2.100'), lessThan(0));
    expect(compareJenkinsVersions('2.516', '2.516.0'), 0);
    expect(compareJenkinsVersions('2.600-SNAPSHOT', '2.599.3'), greaterThan(0));
  });

  test('outdated is strictly older than the baseline', () {
    expect(isOutdatedJenkins('2.401.3', '2.516.1'), isTrue);
    expect(isOutdatedJenkins('2.516.1', '2.516.1'), isFalse);
    expect(isOutdatedJenkins('2.568.3', '2.516.1'), isFalse);
  });
}
