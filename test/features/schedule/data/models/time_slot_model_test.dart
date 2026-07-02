import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/schedule/data/models/time_slot_model.dart';

void main() {
  group('TimeSlotModel.fromJson + toEntity', () {
    test('mappe tous les champs, heures conservées en String', () {
      final json = <String, dynamic>{
        'id': 'ts-1',
        'order': 1,
        'startTime': '08:00:00',
        'endTime': '08:50:00',
        'label': 'P1',
      };

      final entity = TimeSlotModel.fromJson(json).toEntity();

      expect(entity.id, 'ts-1');
      expect(entity.order, 1);
      expect(entity.startTime, '08:00:00');
      expect(entity.endTime, '08:50:00');
      expect(entity.label, 'P1');
    });

    test('label absent -> null', () {
      final json = <String, dynamic>{
        'id': 'ts-2',
        'order': 2,
        'startTime': '09:00:00',
        'endTime': '09:50:00',
      };

      final entity = TimeSlotModel.fromJson(json).toEntity();

      expect(entity.label, isNull);
    });

    test('toJson round-trip', () {
      const model = TimeSlotModel(
        id: 'ts-3',
        order: 3,
        startTime: '10:00:00',
        endTime: '10:50:00',
        label: null,
      );

      final json = model.toJson();

      expect(json['id'], 'ts-3');
      expect(json['order'], 3);
      expect(json['startTime'], '10:00:00');
      expect(json['endTime'], '10:50:00');
      expect(json['label'], isNull);
    });
  });
}
