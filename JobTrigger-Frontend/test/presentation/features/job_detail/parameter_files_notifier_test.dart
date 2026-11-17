import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/parameter_file.dart';
import 'package:job_trigger/presentation/features/job_detail/parameter_files_notifier.dart';

ProviderContainer _container(ParameterFile? picked) {
  final container = ProviderContainer(
    overrides: [
      parameterFilePickerProvider.overrideWithValue(() async => picked),
    ],
  );
  addTearDown(container.dispose);
  container.listen(parameterFilesNotifierProvider('form'), (_, _) {});
  return container;
}

void main() {
  const small = ParameterFile(fileName: 'a.json', path: '/a', sizeBytes: 10);

  test('attaches a picked file under its parameter name', () async {
    final container = _container(small);

    final outcome = await container
        .read(parameterFilesNotifierProvider('form').notifier)
        .pick('config.json');

    expect(outcome, FilePickOutcome.attached);
    expect(container.read(parameterFilesNotifierProvider('form')), {
      'config.json': small,
    });
  });

  test('a cancelled pick changes nothing', () async {
    final container = _container(null);

    final outcome = await container
        .read(parameterFilesNotifierProvider('form').notifier)
        .pick('config.json');

    expect(outcome, FilePickOutcome.cancelled);
    expect(container.read(parameterFilesNotifierProvider('form')), isEmpty);
  });

  test('refuses a file over the limit before it is ever uploaded', () async {
    final container = _container(
      const ParameterFile(
        fileName: 'huge.bin',
        path: '/huge',
        sizeBytes: maxParameterFileBytes + 1,
      ),
    );

    final outcome = await container
        .read(parameterFilesNotifierProvider('form').notifier)
        .pick('config.json');

    expect(outcome, FilePickOutcome.tooLarge);
    expect(container.read(parameterFilesNotifierProvider('form')), isEmpty);
  });

  test('remove detaches a file', () async {
    final container = _container(small);
    final notifier = container.read(
      parameterFilesNotifierProvider('form').notifier,
    );
    await notifier.pick('config.json');

    notifier.remove('config.json');

    expect(container.read(parameterFilesNotifierProvider('form')), isEmpty);
  });
}
