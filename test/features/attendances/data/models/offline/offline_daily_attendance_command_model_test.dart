import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/offline_attendance_update_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/offline_daily_attendance_command_model.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_update.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';

void main() {
  test('round-trip payload d\'outbox (toJsonString / fromJsonString)', () {
    final command = OfflineDailyAttendanceCommandModel(
      classroomId: 'c1',
      date: '2026-06-15',
      academicYearId: 'year-1',
      updates: [
        OfflineAttendanceUpdateModel.fromEntity(
          const AttendanceUpdate(
            studentId: 's1',
            studentFirstName: 'Jean',
            studentLastName: 'Dupont',
            studentGender: StudentGender.female,
            present: false,
            absenceReason: AbsenceReason.sickness,
          ),
          updatedAtMs: 1750000000000,
        ),
        OfflineAttendanceUpdateModel.fromEntity(
          const AttendanceUpdate(
            studentId: 's2',
            studentFirstName: 'Marie',
            studentLastName: 'Curie',
            studentGender: StudentGender.female,
            present: true,
          ),
          updatedAtMs: 1750000000000,
        ),
      ],
    );

    final restored = OfflineDailyAttendanceCommandModel.fromJsonString(
      command.toJsonString(),
    );

    expect(restored, command);
    // full-write : présents ET absents transportés.
    expect(restored.updates, hasLength(2));
    final s1 = restored.updates.first;
    expect(s1.present, isFalse);
    expect(s1.absenceReason, 'SICKNESS');
    expect(s1.updatedAt, endsWith('Z')); // ISO
    // present=true → aucun motif d'absence transporté.
    expect(restored.updates[1].absenceReason, isNull);
  });
}
