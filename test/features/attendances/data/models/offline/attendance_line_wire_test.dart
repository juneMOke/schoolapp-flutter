import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_absence_input_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_line_wire.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_pull_models.dart';

void main() {
  group('ligne d appel v2 sur le fil', () {
    test('un retard reçu au pull est une présence, avec son heure', () {
      final row =
          AbsenceDeltaDto.fromJson(const {
            'id': 'a1',
            'studentId': 's1',
            'status': 'LATE',
            'arrivalTime': '07:48',
            'lateMinutes': 18,
            'absenceReason': 'TRANSPORT',
          }).toLocalRow(
            classroomId: 'c1',
            attendanceDate: '2026-09-29',
            academicYearId: 'y1',
            syncedAt: 1,
          );
      expect(row.present, isTrue);
      expect(row.presenceStatus, PresenceStatus.late);
      expect(row.arrivalTime, '07:48');
      expect(row.lateMinutes, 18);
    });

    test('une ligne d un serveur d avant la v2 est une absence', () {
      final row =
          AbsenceDeltaDto.fromJson(const {
            'id': 'a1',
            'studentId': 's1',
          }).toLocalRow(
            classroomId: 'c1',
            attendanceDate: '2026-09-29',
            academicYearId: 'y1',
            syncedAt: 1,
          );
      expect(row.present, isFalse);
      expect(row.presenceStatus, PresenceStatus.absent);
    });

    test('le statut part toujours, l heure seulement pour un retard', () {
      const absent = AttendanceAbsenceInputModel(
        id: 'a1',
        studentId: 's1',
        updatedAt: '2026-09-29T08:00:00Z',
      );
      expect(absent.toJson()['status'], AttendanceLineWire.absent);
      expect(absent.toJson().containsKey('arrivalTime'), isFalse);

      const late = AttendanceAbsenceInputModel(
        id: 'a2',
        studentId: 's2',
        status: AttendanceLineWire.late,
        arrivalTime: '07:48',
        lateMinutes: 18,
        updatedAt: '2026-09-29T08:00:00Z',
      );
      final json = late.toJson();
      expect(json['status'], 'LATE');
      expect(json['arrivalTime'], '07:48');
      expect(json['lateMinutes'], 18);
      expect(AttendanceAbsenceInputModel.fromJson(json), late);
    });

    test('une présence n a pas de ligne', () {
      expect(
        () => AttendanceLineWire.write(PresenceStatus.present),
        throwsArgumentError,
      );
    });
  });
}
