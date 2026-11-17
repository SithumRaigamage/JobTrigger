import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/models/jenkins/queue_item_dto.dart';

void main() {
  group('QueueItemDto (US-PIPE-01)', () {
    test('still queued: why is present, executable is absent', () {
      final dto = QueueItemDto.fromJson({
        'why': 'Waiting for next available executor',
      });

      expect(dto.why, 'Waiting for next available executor');
      expect(dto.executable, isNull);
      expect(dto.cancelled, isFalse);
      expect(dto.toDomain().isResolved, isFalse);
    });

    test('started building: executable is present', () {
      final dto = QueueItemDto.fromJson({
        'executable': {
          'number': 57,
          'url': 'https://jenkins.test/job/demo/57/',
        },
      });

      final domain = dto.toDomain();
      expect(domain.executable?.number, 57);
      expect(domain.executable?.url, 'https://jenkins.test/job/demo/57/');
      expect(domain.isResolved, isTrue);
    });

    test('cancelled while still queued', () {
      final dto = QueueItemDto.fromJson({'cancelled': true});

      final domain = dto.toDomain();
      expect(domain.cancelled, isTrue);
      expect(domain.executable, isNull);
      expect(domain.isResolved, isTrue);
    });
  });
}
