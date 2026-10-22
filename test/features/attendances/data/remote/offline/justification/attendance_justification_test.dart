import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/justification/attendance_justification_dto.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/justification/attendance_justification_page_dto.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/justification/justification_decision_payload.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/justification/attendance_justification_api.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/justification/attendance_justification_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/justification/justification_decision_outbox_handler.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/attendance_justification.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/justification_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../../../../core/offline/offline_full_test_db.dart';

class _Api extends Mock implements AttendanceJustificationApi {}

void main() {
  late Database db;
  late AttendanceJustificationLocalDataSource local;
  late OutboxDao outbox;
  late _Api api;
  late CurrentUserContext user;
  late JustificationDecisionOutboxHandler handler;

  AttendanceJustificationDto dto({
    String status = 'PENDING',
    String? decisionNote,
    Map<String, dynamic>? file,
  }) => AttendanceJustificationDto.fromJson({
    'id': 'j1',
    'studentId': 's1',
    'classroomId': 'c1',
    'academicYearId': 'y1',
    'attendanceDate': '2026-10-14',
    'parentId': 'p1',
    'reason': 'SICKNESS',
    'note': 'Fièvre',
    'submittedAt': '2026-10-15T07:12:00Z',
    'file': ?file,
    'status': status,
    'decisionNote': decisionNote,
    'serverUpdatedAt': '2026-10-15T07:12:00Z',
  });

  Future<AttendanceJustification> only() async =>
      (await local.list('y1')).single;

  Future<JustificationDecisionPayload> decide(
    JustificationDecision decision, {
    String? note,
  }) async {
    final payload = JustificationDecisionPayload(
      gestureId: 'g-${decision.apiValue}',
      justificationId: 'j1',
      decision: decision.apiValue,
      note: note,
      authorId: 'uid-1',
    );
    final recorded = await local.recordDecision(
      payload: payload,
      schoolId: 'school-1',
      nowMs: 1000,
    );
    expect(recorded, isTrue);
    return payload;
  }

  Future<OutboxEntry> entry() async =>
      (await outbox.pendingReady(999999)).single;

  DioException refused(int status, {String? detailCode}) => DioException(
    requestOptions: RequestOptions(path: '/decision'),
    error: status == 422 ? const ValidationFailure() : null,
    response: Response<dynamic>(
      requestOptions: RequestOptions(path: '/decision'),
      statusCode: status,
      data: {'detailCode': ?detailCode},
    ),
  );

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() async {
    db = await openFullOfflineDb();
    local = AttendanceJustificationLocalDataSource(db);
    outbox = OutboxDao(db);
    api = _Api();
    user = CurrentUserContext()..set('uid-1', schoolId: 'school-1');
    handler = JustificationDecisionOutboxHandler(
      api: api,
      justifications: local,
      requiredAuth: const {},
      currentUser: user,
    );
    await db.insert('ref_classroom_members', {
      'id': 'm1',
      'student_id': 's1',
      'classroom_id': 'c1',
      'academic_year_id': 'y1',
      'student_first_name': 'Grace',
      'student_last_name': 'Boboto',
      'student_middle_name': 'Lisanga',
    });
    await db.insert('ref_classrooms', {
      'id': 'c1',
      'academic_year_id': 'y1',
      'name': '6e A',
    });
    await local.applyPulled([
      dto(
        file: {
          'name': 'certificat.pdf',
          'mimeType': 'application/pdf',
          'sizeBytes': 182000,
          'sha256': 'abc',
        },
      ),
    ]);
  });

  tearDown(() => db.close());

  group('lecture', () {
    test('la demande se lit avec l élève et la classe du roster', () async {
      final j = await only();
      expect(j.studentName, 'Boboto Lisanga Grace');
      expect(j.classroomName, '6e A');
      expect(j.reason, AbsenceReason.sickness);
      expect(j.attachment?.sha256, 'abc');
      expect(j.attachment?.isPdf, isTrue);
      expect(j.awaitsDecision, isTrue);
      expect(j.canAccept, isTrue);
    });

    test('une page tolère une ligne illisible', () {
      final page = AttendanceJustificationPageDto.fromJson({
        'items': [
          {'id': 'sans-eleve'},
          dto().toJsonForTest(),
        ],
        'hasMore': false,
        'serverTime': '2026-10-15T08:00:00Z',
      });
      expect(page.items.map((i) => i.id), ['j1']);
    });
  });

  group('décision locale', () {
    test(
      'elle part en file avec l auteur, et la demande est en route',
      () async {
        await decide(JustificationDecision.reject, note: 'Pas de certificat');
        final queued = await entry();
        expect(queued.aggregateType, kJustificationDecisionAggregateType);
        expect(queued.aggregateId, 'j1');
        expect(queued.schoolId, 'school-1');
        final payload = JustificationDecisionPayload.fromJsonString(
          queued.payload,
        );
        expect(payload.toWireJson(), {
          'gestureId': 'g-REJECT',
          'decision': 'REJECT',
          'note': 'Pas de certificat',
          'authorId': 'uid-1',
        });
        final j = await only();
        expect(j.isSending, isTrue);
        expect(j.awaitsDecision, isFalse);
        expect(j.isOpen, isTrue);
      },
    );

    test(
      'une seconde décision est refusée tant que la première roule',
      () async {
        await decide(JustificationDecision.accept);
        final again = await local.recordDecision(
          payload: const JustificationDecisionPayload(
            gestureId: 'g-2',
            justificationId: 'j1',
            decision: 'REJECT',
          ),
          schoolId: 'school-1',
          nowMs: 2000,
        );
        expect(again, isFalse);
        expect(await outbox.pendingReady(999999), hasLength(1));
      },
    );

    test('un pull pendant l envoi ne défait pas la décision locale', () async {
      await decide(JustificationDecision.accept);
      await local.applyPulled([dto()]);
      expect((await only()).localDecision, JustificationDecision.accept);
    });
  });

  group('envoi', () {
    test(
      '200 : la décision du serveur s écrit, la demande est tranchée',
      () async {
        await decide(JustificationDecision.accept);
        when(
          () => api.decide(any(), 'j1', any()),
        ).thenAnswer((_) async => dto(status: 'ACCEPTED'));

        final result = await handler.dispatch(await entry());

        expect(result.outcome, OutboxDispatchOutcome.acked);
        final j = await only();
        expect(j.status, JustificationStatus.accepted);
        expect(j.localDecision, isNull);
        expect(j.decidedElsewhere, isFalse);
        expect(j.sync, SyncState.synced);
      },
    );

    test(
      '200 avec la décision d une autre tablette : c est elle qui reste',
      () async {
        await decide(JustificationDecision.accept);
        when(() => api.decide(any(), 'j1', any())).thenAnswer(
          (_) async => dto(status: 'REJECTED', decisionNote: 'Hors délai'),
        );

        await handler.dispatch(await entry());

        final j = await only();
        expect(j.status, JustificationStatus.rejected);
        expect(j.decisionNote, 'Hors délai');
        expect(j.decidedElsewhere, isTrue);
        await local.acknowledgeDecidedElsewhere('j1');
        expect((await only()).decidedElsewhere, isFalse);
      },
    );

    for (final block in JustificationAcceptBlock.values) {
      test('422 ${block.code} : à traiter, seul le refus reste', () async {
        await decide(JustificationDecision.accept);
        when(
          () => api.decide(any(), 'j1', any()),
        ).thenThrow(refused(422, detailCode: block.code));

        final result = await handler.dispatch(await entry());

        expect(result.outcome, OutboxDispatchOutcome.acked);
        final j = await only();
        expect(j.awaitsDecision, isTrue);
        expect(j.acceptBlock, block);
        expect(j.canAccept, isFalse);
        expect(j.canReject, isTrue);
        expect(j.refusal, isNull);
      });
    }

    test('le blocage disparaît quand la demande est tranchée', () async {
      await decide(JustificationDecision.accept);
      when(
        () => api.decide(any(), 'j1', any()),
      ).thenThrow(refused(422, detailCode: 'MONTH_CLOSED'));
      await handler.dispatch(await entry());
      await local.applyPulled([dto(status: 'REJECTED')]);
      expect((await only()).acceptBlock, isNull);
    });

    test(
      '422 DECISION_GESTURE_ID_CONFLICT : à traiter, sans rien dire',
      () async {
        await decide(JustificationDecision.reject, note: 'Non');
        when(
          () => api.decide(any(), 'j1', any()),
        ).thenThrow(refused(422, detailCode: kDecisionGestureIdConflictCode));

        final result = await handler.dispatch(await entry());

        expect(result.outcome, OutboxDispatchOutcome.acked);
        final j = await only();
        expect(j.awaitsDecision, isTrue);
        expect(j.refusal, isNull);
        expect(j.acceptBlock, isNull);
      },
    );

    test('403 d un autre compte : attente propre, rien ne bouge', () async {
      await decide(JustificationDecision.accept);
      user.set('uid-2', schoolId: 'school-1');
      when(() => api.decide(any(), 'j1', any())).thenThrow(refused(403));

      final result = await handler.dispatch(await entry());

      expect(result.outcome, OutboxDispatchOutcome.blocked);
      expect((await only()).isSending, isTrue);
    });

    test(
      '403 du compte connecté : refus montré, la demande se retranche',
      () async {
        await decide(JustificationDecision.accept);
        when(() => api.decide(any(), 'j1', any())).thenThrow(refused(403));

        final result = await handler.dispatch(await entry());

        expect(result.outcome, OutboxDispatchOutcome.failed);
        final j = await only();
        expect(j.awaitsDecision, isTrue);
        expect(j.refusal, isNotNull);
        expect(j.sync, SyncState.syncError);
      },
    );

    test('réseau ou 5xx : nouvel essai, la décision reste en route', () async {
      await decide(JustificationDecision.accept);
      when(() => api.decide(any(), 'j1', any())).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/decision')),
      );

      final result = await handler.dispatch(await entry());

      expect(result.outcome, OutboxDispatchOutcome.retry);
      expect((await only()).isSending, isTrue);
    });

    test('une écriture d une autre école attend sa session', () async {
      await decide(JustificationDecision.accept);
      user.set('uid-1', schoolId: 'school-2');

      final result = await handler.dispatch(await entry());

      expect(result.outcome, OutboxDispatchOutcome.blocked);
      verifyNever(() => api.decide(any(), any(), any()));
    });
  });
}

extension on AttendanceJustificationDto {
  Map<String, dynamic> toJsonForTest() => {
    'id': id,
    'studentId': studentId,
    'classroomId': classroomId,
    'academicYearId': academicYearId,
    'attendanceDate': attendanceDate,
    'reason': reason,
    'status': status,
  };
}
