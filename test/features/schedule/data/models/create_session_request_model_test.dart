import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/schedule/data/models/create_session_request_model.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/create_session_request.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';

void main() {
  group('CreateSessionRequestModel.fromDomain + toJson', () {
    test('day sérialisé en wire, room présent -> émis', () {
      const request = CreateSessionRequest(
        coursId: 'cours-1',
        academicYearId: 'ay-1',
        day: Weekday.thu,
        timeSlotId: 'ts-1',
        room: 'Salle 5',
      );

      final json = CreateSessionRequestModel.fromDomain(request).toJson();

      expect(json['coursId'], 'cours-1');
      expect(json['academicYearId'], 'ay-1');
      expect(json['day'], 'THU');
      expect(json['timeSlotId'], 'ts-1');
      expect(json['room'], 'Salle 5');
    });

    test('room null -> clé omise', () {
      const request = CreateSessionRequest(
        coursId: 'cours-2',
        academicYearId: 'ay-1',
        day: Weekday.mon,
        timeSlotId: 'ts-2',
      );

      final json = CreateSessionRequestModel.fromDomain(request).toJson();

      expect(json['day'], 'MON');
      expect(json.containsKey('room'), isFalse);
    });
  });
}
