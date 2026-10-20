import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/presentation/features/job_detail/parameter_edits_notifier.dart';

void main() {
  test('records edits per form key, independently', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(parameterEditsNotifierProvider('a'), (_, _) {});
    container.listen(parameterEditsNotifierProvider('b'), (_, _) {});

    container.read(parameterEditsNotifierProvider('a').notifier)
      ..setValue('BRANCH', 'x')
      ..setValue('BRANCH', 'y');
    container
        .read(parameterEditsNotifierProvider('b').notifier)
        .setValue('TARGET', 'prod');

    expect(container.read(parameterEditsNotifierProvider('a')), {
      'BRANCH': 'y',
    });
    expect(container.read(parameterEditsNotifierProvider('b')), {
      'TARGET': 'prod',
    });

    container.read(parameterEditsNotifierProvider('a').notifier).clear();
    expect(container.read(parameterEditsNotifierProvider('a')), isEmpty);
  });
}
