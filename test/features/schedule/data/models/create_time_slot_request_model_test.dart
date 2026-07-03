import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/schedule/data/models/create_time_slot_request_model.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/create_time_slot_request.dart';

void main() {
  group('CreateTimeSlotRequestModel.fromDomain + toJson', () {
    test('label présent -> émis', () {
      const request = CreateTimeSlotRequest(
        order: 1,
        startTime: '08:00:00',
        endTime: '08:50:00',
        label: 'P1',
      );

      final json = CreateTimeSlotRequestModel.fromDomain(request).toJson();

      expect(json['order'], 1);
      expect(json['startTime'], '08:00:00');
      expect(json['endTime'], '08:50:00');
      expect(json['label'], 'P1');
    });

    test('label null -> clé omise', () {
      const request = CreateTimeSlotRequest(
        order: 2,
        startTime: '09:00:00',
        endTime: '09:50:00',
      );

      final json = CreateTimeSlotRequestModel.fromDomain(request).toJson();

      expect(json.containsKey('label'), isFalse);
    });
  });
}
