import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/network/request_id.dart';

void main() {
  test('ids are 16 hex characters the backend accepts', () {
    for (var i = 0; i < 50; i++) {
      final id = newRequestId();
      expect(id, matches(RegExp(r'^[0-9a-f]{16}$')));
      expect(id, matches(requestIdPattern));
    }
  });

  test('ids differ', () {
    final random = Random(1);
    expect(newRequestId(random), isNot(newRequestId(random)));
  });
}
