import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_aggregate_request_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_session_input_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/disciplinary_case_aggregate_request_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/disciplinary_case_input_model.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_transfer_row.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_aggregate_request.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_outbox_payload.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_push_request_models.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

/// ADR-010 D-05 / G-crit : le champ `authorId` doit voyager au **top-level** de
/// chaque payload `/sync` (la garde serveur A3 lit `request.authorId()`), et
/// **survivre au round-trip** `fromJson(toJson)` (les handlers reparsent le
/// payload figé de l'outbox avant de le poster).
const _uid = '3fa85f64-5717-4562-b3fc-2c963f66afa6';

void main() {
  test('FINANCE : authorId top-level + round-trip', () {
    final req = const PaymentAggregateRequest(
      authorId: _uid,
      payment: PaymentInput(
        id: 'p1',
        studentId: 's1',
        academicYearId: 'ay1',
        method: 'CASH',
        amounts: MoneyBag.empty,
        paidAt: '2026-07-19T10:00:00Z',
      ),
      allocations: [],
    );
    expect(req.toJson()['authorId'], _uid);
    expect(PaymentAggregateRequest.fromJson(req.toJson()).authorId, _uid);
  });

  test('ATTENDANCE : authorId top-level + round-trip', () {
    final req = const AttendanceAggregateRequestModel(
      authorId: _uid,
      session: AttendanceSessionInputModel(
        id: 'sess1',
        classroomId: 'c1',
        attendanceDate: '2026-07-19',
        academicYearId: 'ay1',
        takenAt: '2026-07-19T10:00:00Z',
        updatedAt: '2026-07-19T10:00:00Z',
      ),
      absences: [],
    );
    expect(req.toJson()['authorId'], _uid);
    expect(
      AttendanceAggregateRequestModel.fromJsonString(
        req.toJsonString(),
      ).authorId,
      _uid,
    );
  });

  test('DISCIPLINARY : authorId top-level + round-trip', () {
    final req = const DisciplinaryCaseAggregateRequestModel(
      authorId: _uid,
      caseInput: DisciplinaryCaseInputModel(
        id: 'd1',
        studentId: 's1',
        academicYearId: 'ay1',
        category: 'DISRUPTIVE_BEHAVIOR',
        severity: 'MINOR',
        title: 'Incident',
        content: 'Détail',
        disciplinaryCaseDate: '2026-07-19',
        status: 'OPEN',
        clientUpdatedAt: '2026-07-19T10:00:00Z',
      ),
    );
    expect(req.toJson()['authorId'], _uid);
    expect(
      DisciplinaryCaseAggregateRequestModel.fromJsonString(
        req.toJsonString(),
      ).authorId,
      _uid,
    );
  });

  test('CLASSROOM : authorId top-level (post brut, pas de reshape)', () {
    final row = const ClassroomTransferRow(
      id: 't1',
      studentId: 's1',
      fromClassroomId: 'c1',
      toClassroomId: 'c2',
      schoolLevelId: 'sl1',
      academicYearId: 'ay1',
      transferredAt: 1000,
      syncStatus: 'PENDING_SYNC',
    );
    final json = row.toRequestJson(authorId: _uid);
    expect(json['authorId'], _uid);
    expect((json['transfer'] as Map)['id'], 't1');
    // Sans uid (session héritée) : pas de champ authorId (le serveur 403).
    expect(row.toRequestJson().containsKey('authorId'), isFalse);
  });

  test(
    'ENROLLMENT : authorId figé dans la commande + recopié au reshape wire',
    () {
      const command = EnrollmentCommand(
        authorId: _uid,
        enrollment: EnrollmentPayload(
          id: 'e1',
          schoolLevelId: 'sl1',
          academicYearId: 'ay1',
          enrollmentType: 'NEW',
          status: 'ENROLLED',
          enrollmentDate: '2026-07-19',
        ),
        student: StudentPayload(
          id: 's1',
          firstName: 'Amina',
          lastName: 'Kalala',
          surname: 'Kalala',
          gender: 'FEMALE',
          dateOfBirth: '2015-01-01',
          birthPlace: 'Kinshasa',
          nationality: 'CD',
        ),
        parents: [],
      );
      // Payload figé de l'outbox.
      expect(command.toJson()['authorId'], _uid);
      expect(EnrollmentCommand.fromJson(command.toJson()).authorId, _uid);
      // Reshape wire (dispatch) : recopie au top-level.
      expect(
        const EnrollmentAggregateRequest(command).toJson()['authorId'],
        _uid,
      );
    },
  );
}
