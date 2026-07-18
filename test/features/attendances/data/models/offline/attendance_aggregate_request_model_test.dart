import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_absence_input_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_aggregate_request_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_session_input_model.dart';

/// Verrouille la forme de l'agrégat d'appel (contrat 1.2.0) et son round-trip
/// via le payload d'outbox (invariant #3 : liste d'absences EXHAUSTIVE, vide légitime).
void main() {
  AttendanceAggregateRequestModel aggregate(
    List<AttendanceAbsenceInputModel> absences,
  ) => AttendanceAggregateRequestModel(
    session: const AttendanceSessionInputModel(
      id: 'sess-1',
      classroomId: 'c1',
      attendanceDate: '2026-06-15',
      academicYearId: 'year-1',
      takenAt: '2026-06-15T08:00:00.000Z',
      updatedAt: '2026-06-15T08:00:00.000Z',
    ),
    absences: absences,
  );

  const absence = AttendanceAbsenceInputModel(
    id: 'abs-1',
    studentId: 's1',
    absenceReason: 'SICKNESS',
    absenceReasonNote: 'fièvre',
    updatedAt: '2026-06-15T08:00:00.000Z',
  );

  test('round-trip payload d\'outbox (toJsonString/fromJsonString)', () {
    final decoded = AttendanceAggregateRequestModel.fromJsonString(
      aggregate([absence]).toJsonString(),
    );
    expect(decoded.session.id, 'sess-1');
    expect(decoded.session.classroomId, 'c1');
    expect(decoded.absences, hasLength(1));
    expect(decoded.absences.single.studentId, 's1');
    expect(decoded.absences.single.absenceReason, 'SICKNESS');
    expect(decoded.absences.single.absenceReasonNote, 'fièvre');
  });

  test(
    'liste d\'absences vide = légitime (appel fait, personne d\'absent)',
    () {
      final decoded = AttendanceAggregateRequestModel.fromJsonString(
        aggregate(const []).toJsonString(),
      );
      expect(decoded.absences, isEmpty);
      expect(decoded.session.id, 'sess-1');
    },
  );

  test('toJson : la session ne transmet pas expected_count/present', () {
    final json = aggregate([absence]).toJson();
    expect((json['session'] as Map).containsKey('expectedCount'), isFalse);
    // `present` n'existe pas dans l'exception : une ligne EST l'absence.
    expect((json['absences'] as List).first, isNot(contains('present')));
  });
}
