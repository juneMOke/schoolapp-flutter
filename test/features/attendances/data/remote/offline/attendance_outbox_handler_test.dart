import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_absence_input_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_aggregate_request_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_aggregate_response_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_session_input_model.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_outbox_handler.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_sync_api.dart';

class MockAttendanceSyncApi extends Mock implements AttendanceSyncApi {}

class MockAttendanceLocalDataSource extends Mock
    implements AttendanceLocalDataSource {}

class FakeAggregate extends Fake implements AttendanceAggregateRequestModel {}

void main() {
  late MockAttendanceSyncApi api;
  late MockAttendanceLocalDataSource local;
  late AttendanceOutboxHandler handler;

  const auth = <String, dynamic>{'requiresAuth': true};

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(FakeAggregate());
  });

  /// Élèves que la sonde CLASSE → PRÉSENCE déclare sous transfert non
  /// synchronisé. Vide par défaut : le cas nominal ne bloque rien.
  late Set<String> pendingTransfers;

  /// Arguments reçus par la sonde, pour prouver qu'elle est bien interrogée sur
  /// les ABSENTS de l'agrégat et sur SON année.
  List<String>? probedStudentIds;
  String? probedAcademicYearId;

  setUp(() {
    api = MockAttendanceSyncApi();
    local = MockAttendanceLocalDataSource();
    pendingTransfers = <String>{};
    probedStudentIds = null;
    probedAcademicYearId = null;
    handler = AttendanceOutboxHandler(
      syncApi: api,
      localDataSource: local,
      requiredAuth: auth,
      pendingTransfers: (studentIds, academicYearId) async {
        probedStudentIds = studentIds;
        probedAcademicYearId = academicYearId;
        return pendingTransfers;
      },
      now: () => 7000,
    );
  });

  // `authorId` estampillé à la SAISIE (ADR-010 D-05) : c'est lui que le serveur
  // compare à l'uid du jeton présenté.
  const aggregate = AttendanceAggregateRequestModel(
    authorId: 'author-1',
    session: AttendanceSessionInputModel(
      id: 'sess-1',
      classroomId: 'c1',
      attendanceDate: '2026-06-15',
      academicYearId: 'year-1',
      takenAt: '2026-06-15T00:00:00.000Z',
      updatedAt: '2026-06-15T00:00:00.000Z',
    ),
    absences: [
      AttendanceAbsenceInputModel(
        id: 'abs-1',
        studentId: 's1',
        absenceReason: 'SICKNESS',
        updatedAt: '2026-06-15T00:00:00.000Z',
      ),
    ],
  );

  AttendanceAggregateResponseModel response({
    String outcome = 'APPLIED',
    String? serverUpdatedAt = '2026-06-15T09:00:00.000Z',
    int? expectedCount = 40,
    String? updatedAt,
    List<AttendanceAbsenceAck> absences = const [],
  }) => AttendanceAggregateResponseModel(
    sessionId: 'sess-1',
    serverUpdatedAt: serverUpdatedAt,
    expectedCount: expectedCount,
    lwwOutcome: outcome,
    updatedAt: updatedAt,
    absences: absences,
  );

  OutboxEntry entry({String? payload}) => OutboxEntry(
    id: 'ATTENDANCE:c1|2026-06-15|year-1',
    aggregateType: 'ATTENDANCE',
    aggregateId: 'c1|2026-06-15|year-1',
    operation: OutboxOperation.upsert,
    payload: payload ?? aggregate.toJsonString(),
    createdAt: 1000,
  );

  /// Handler dont le porteur du jeton est [uid] — permet de distinguer un 403
  /// d'attribution (auteur absent de la session courante) d'un 403 réellement
  /// terminal.
  AttendanceOutboxHandler handlerFor({required String uid}) {
    final ctx = CurrentUserContext()..set(uid);
    return AttendanceOutboxHandler(
      syncApi: api,
      localDataSource: local,
      requiredAuth: auth,
      pendingTransfers: (_, _) async => pendingTransfers,
      currentUser: ctx,
      now: () => 7000,
    );
  }

  DioException dio(Object? error, {int? status, Object? body}) => DioException(
    requestOptions: RequestOptions(path: '/sync/attendance'),
    error: error,
    response: status == null && body == null
        ? null
        : Response<dynamic>(
            requestOptions: RequestOptions(path: '/sync/attendance'),
            statusCode: status,
            data: body,
          ),
  );

  void stubMarkSynced() {
    when(
      () => local.markDaySynced(
        classroomId: any(named: 'classroomId'),
        dateStr: any(named: 'dateStr'),
        academicYearId: any(named: 'academicYearId'),
        syncedAt: any(named: 'syncedAt'),
        serverUpdatedAt: any(named: 'serverUpdatedAt'),
        expectedCount: any(named: 'expectedCount'),
      ),
    ).thenAnswer((_) async {});
  }

  test('type d\'agrégat = ATTENDANCE', () {
    expect(handler.aggregateType, 'ATTENDANCE');
  });

  test(
    'APPLIED → synced + rapatrie serverUpdatedAt/expectedCount (AG-3)',
    () async {
      when(
        () => api.submitAttendance(any(), any()),
      ).thenAnswer((_) async => response());
      stubMarkSynced();

      final result = await handler.dispatch(entry());

      expect(result.outcome, OutboxDispatchOutcome.acked);
      verify(
        () => local.markDaySynced(
          classroomId: 'c1',
          dateStr: '2026-06-15',
          academicYearId: 'year-1',
          syncedAt: 7000,
          serverUpdatedAt: '2026-06-15T09:00:00.000Z',
          expectedCount: 40,
        ),
      ).called(1);
    },
  );

  test(
    'SUPERSEDED → adopte l\'état canonique du gagnant, jamais markDaySynced',
    () async {
      // Le serveur sort AVANT toute écriture : notre version a perdu. On ne
      // doit ni sceller nos valeurs (divergence muette), ni laisser la session
      // PENDING_SYNC (elle deviendrait invisible au pull, donc irréparable).
      when(() => api.submitAttendance(any(), any())).thenAnswer(
        (_) async => response(
          outcome: 'SUPERSEDED',
          updatedAt: '2026-06-15T10:00:00.000Z',
          absences: const [
            AttendanceAbsenceAck(
              studentId: 's9',
              absenceReason: 'LATE',
              updatedAt: '2026-06-15T10:00:00.000Z',
            ),
          ],
        ),
      );
      when(
        () => local.adoptCanonicalDay(
          classroomId: any(named: 'classroomId'),
          dateStr: any(named: 'dateStr'),
          academicYearId: any(named: 'academicYearId'),
          canonicalAbsences: any(named: 'canonicalAbsences'),
          updatedAt: any(named: 'updatedAt'),
          syncedAt: any(named: 'syncedAt'),
          serverUpdatedAt: any(named: 'serverUpdatedAt'),
          expectedCount: any(named: 'expectedCount'),
        ),
      ).thenAnswer((_) async {});
      stubMarkSynced();

      final result = await handler.dispatch(entry());

      expect(result.outcome, OutboxDispatchOutcome.acked);
      final captured =
          verify(
                () => local.adoptCanonicalDay(
                  classroomId: 'c1',
                  dateStr: '2026-06-15',
                  academicYearId: 'year-1',
                  canonicalAbsences: captureAny(named: 'canonicalAbsences'),
                  // Jeton du GAGNANT : rester sur le nôtre ferait reperdre tous les
                  // arbitrages suivants.
                  updatedAt: DateTime.utc(
                    2026,
                    6,
                    15,
                    10,
                  ).millisecondsSinceEpoch,
                  syncedAt: 7000,
                  serverUpdatedAt: any(named: 'serverUpdatedAt'),
                  expectedCount: any(named: 'expectedCount'),
                ),
              ).captured.single
              as Map<String, CanonicalAbsence>;
      expect(captured.keys, ['s9']);
      expect(captured['s9']!.absenceReason, 'LATE');

      verifyNever(
        () => local.markDaySynced(
          classroomId: any(named: 'classroomId'),
          dateStr: any(named: 'dateStr'),
          academicYearId: any(named: 'academicYearId'),
          syncedAt: any(named: 'syncedAt'),
          serverUpdatedAt: any(named: 'serverUpdatedAt'),
          expectedCount: any(named: 'expectedCount'),
        ),
      );
    },
  );

  test('réseau (NetworkFailure) → retry', () async {
    when(
      () => api.submitAttendance(any(), any()),
    ).thenThrow(dio(const NetworkFailure()));

    final result = await handler.dispatch(entry());
    expect(result.outcome, OutboxDispatchOutcome.retry);
  });

  test('403 auteur == utilisateur courant → failed (pas 50 retries)', () async {
    // Le refus ne vient pas de l'attribution : il ne se réparera pas seul.
    when(
      () => api.submitAttendance(any(), any()),
    ).thenThrow(dio(const UnauthorizedFailure('forbidden'), status: 403));

    final result = await handlerFor(uid: 'author-1').dispatch(entry());
    expect(result.outcome, OutboxDispatchOutcome.failed);
  });

  test('403 auteur != utilisateur courant → blocked (tablette partagée)', () async {
    // `SyncAttributionGuard` refuse le JETON PRÉSENTÉ, pas l'écriture : l'appel
    // de A flushé sous la session de B repartira tel quel à la reconnexion de A.
    // Le classer terminal brûlerait un appel parfaitement valide.
    when(
      () => api.submitAttendance(any(), any()),
    ).thenThrow(dio(const UnauthorizedFailure('forbidden'), status: 403));

    final result = await handlerFor(uid: 'someone-else').dispatch(entry());
    expect(result.outcome, OutboxDispatchOutcome.blocked);
  });

  test('401 (ré-auth) reste transitoire', () async {
    when(
      () => api.submitAttendance(any(), any()),
    ).thenThrow(dio(const UnauthorizedFailure('expired'), status: 401));

    final result = await handler.dispatch(entry());
    expect(result.outcome, OutboxDispatchOutcome.retry);
  });

  test('rejet métier (ValidationFailure) → failed', () async {
    when(
      () => api.submitAttendance(any(), any()),
    ).thenThrow(dio(const ValidationFailure('bad')));

    final result = await handler.dispatch(entry());
    expect(result.outcome, OutboxDispatchOutcome.failed);
  });

  test('payload corrompu → failed (jamais rejouable)', () async {
    final result = await handler.dispatch(entry(payload: 'not-json'));
    expect(result.outcome, OutboxDispatchOutcome.failed);
    verifyNever(() => api.submitAttendance(any(), any()));
  });

  group('agrégat sans auteur (ADR-010 D-05)', () {
    /// Même agrégat, `authorId` absent — l'état d'une tablette dont la session
    /// n'a jamais porté d'uid (jeton hérité sans le claim, amorçage manqué).
    final unauthored = AttendanceAggregateRequestModel(
      session: aggregate.session,
      absences: aggregate.absences,
    );

    test(
      'rejeté sans aller-retour : le serveur le refuserait toujours',
      () async {
        // `authorId` est `@NotNull` côté serveur : la validation du corps rejette
        // en 400 AVANT même la garde d'attribution. Pousser, c'était brûler un
        // appel réseau pour un refus certain.
        final result = await handler.dispatch(
          entry(payload: unauthored.toJsonString()),
        );

        expect(result.outcome, OutboxDispatchOutcome.failed);
        verifyNever(() => api.submitAttendance(any(), any()));
      },
    );

    test('le refus dit le geste qui répare', () async {
      // L'ancien libellé venait de l'intercepteur (« Invalid request data ») :
      // ni la cause ni la sortie. Réenfiler le même jour avec un auteur est la
      // seule issue — encore faut-il que la feuille de reprise le dise.
      final result = await handler.dispatch(
        entry(payload: unauthored.toJsonString()),
      );

      expect(result.error, contains('sans auteur'));
      expect(result.error, contains('réenregistrez'));
    });
  });

  group('garde CLASSE → PRÉSENCE (transfert non synchronisé)', () {
    test(
      'un absent sous transfert en vol → blocked, rien n\'est poussé',
      () async {
        // Le roster de l'appel est COMPOSÉ, celui que valide le serveur ne l'est
        // pas : pousser ferait rejeter l'agrégat ENTIER en 422 terminal, donc
        // perdrait la journée complète de la classe pour un seul élève.
        pendingTransfers = {'s1'};

        final result = await handler.dispatch(entry());

        expect(result.outcome, OutboxDispatchOutcome.blocked);
        verifyNever(() => api.submitAttendance(any(), any()));
      },
    );

    test(
      'la sonde est interrogée sur les ABSENTS et sur l\'année de l\'appel',
      () async {
        when(
          () => api.submitAttendance(any(), any()),
        ).thenAnswer((_) async => response());
        stubMarkSynced();

        await handler.dispatch(entry());

        expect(probedStudentIds, ['s1']);
        expect(probedAcademicYearId, 'year-1');
      },
    );

    test('aucun transfert en vol → l\'appel part normalement', () async {
      when(
        () => api.submitAttendance(any(), any()),
      ).thenAnswer((_) async => response());
      stubMarkSynced();

      final result = await handler.dispatch(entry());

      expect(result.outcome, OutboxDispatchOutcome.acked);
    });
  });

  group('raison du refus lisible', () {
    test(
      '422 : c\'est le message du SERVEUR qui atterrit dans la file',
      () async {
        // L'intercepteur aplatit tout 400/422 sur « Invalid request data » ; la
        // feuille de reprise n'affichait donc jamais la cause, alors que le corps
        // la porte mot pour mot.
        when(() => api.submitAttendance(any(), any())).thenThrow(
          dio(
            const ValidationFailure('Invalid request data'),
            status: 422,
            body: <String, dynamic>{
              'status': 422,
              'code': 'UNPROCESSABLE',
              'message': 'Student not in the active roster of this class: s1',
            },
          ),
        );

        final result = await handler.dispatch(entry());

        expect(result.outcome, OutboxDispatchOutcome.failed);
        expect(
          result.error,
          'Student not in the active roster of this class: s1',
        );
      },
    );

    test('403 terminal : même lecture', () async {
      when(() => api.submitAttendance(any(), any())).thenThrow(
        dio(
          const UnauthorizedFailure('Access forbidden'),
          status: 403,
          body: <String, dynamic>{
            'message':
                'Corriger un appel d\'un jour révolu exige la permission '
                'attendance.amend',
          },
        ),
      );

      final result = await handlerFor(uid: 'author-1').dispatch(entry());

      expect(result.outcome, OutboxDispatchOutcome.failed);
      expect(result.error, contains('attendance.amend'));
    });

    test('corps sans message : on garde le libellé du socle', () async {
      when(
        () => api.submitAttendance(any(), any()),
      ).thenThrow(dio(const ValidationFailure('bad'), status: 422));

      final result = await handler.dispatch(entry());

      expect(result.error, 'bad');
    });
  });

  group('SUPERSEDED : jeton LWW réancré sur la réponse, jamais sur la tablette', () {
    /// Epoch d'un instant ISO — l'horloge du handler est figée à 7000 ms, donc
    /// toute valeur issue de la réponse s'en distingue sans ambiguïté.
    int epochOf(String iso) => DateTime.parse(iso).millisecondsSinceEpoch;

    Future<int> adoptedToken() async {
      when(
        () => local.adoptCanonicalDay(
          classroomId: any(named: 'classroomId'),
          dateStr: any(named: 'dateStr'),
          academicYearId: any(named: 'academicYearId'),
          canonicalAbsences: any(named: 'canonicalAbsences'),
          updatedAt: any(named: 'updatedAt'),
          syncedAt: any(named: 'syncedAt'),
          serverUpdatedAt: any(named: 'serverUpdatedAt'),
          expectedCount: any(named: 'expectedCount'),
        ),
      ).thenAnswer((_) async {});
      stubMarkSynced();

      await handler.dispatch(entry());

      return verify(
            () => local.adoptCanonicalDay(
              classroomId: any(named: 'classroomId'),
              dateStr: any(named: 'dateStr'),
              academicYearId: any(named: 'academicYearId'),
              canonicalAbsences: any(named: 'canonicalAbsences'),
              updatedAt: captureAny(named: 'updatedAt'),
              syncedAt: any(named: 'syncedAt'),
              serverUpdatedAt: any(named: 'serverUpdatedAt'),
              expectedCount: any(named: 'expectedCount'),
            ),
          ).captured.single
          as int;
    }

    test(
      'le contrat ne porte PAS session.updatedAt : on ne retombe pas sur now()',
      () async {
        // C'est le cas RÉEL : `AttendanceAggregateResponse.session` n'expose que
        // id / serverUpdatedAt / expectedCount. Le repli d'origine était
        // l'horloge de la tablette — précisément celle qui retarde quand un
        // SUPERSEDED survient, donc un jeton encore perdant, donc la journée
        // condamnée à reperdre tous les arbitrages suivants.
        when(() => api.submitAttendance(any(), any())).thenAnswer(
          (_) async => response(outcome: 'SUPERSEDED', updatedAt: null),
        );

        expect(await adoptedToken(), epochOf('2026-06-15T09:00:00.000Z'));
      },
    );

    test(
      'on prend le plus tardif de ce que la réponse porte vraiment',
      () async {
        // Les ACK d'absence, eux, portent de vrais jetons client : le gagnant y
        // est mieux approché que par son seul temps de commit.
        when(() => api.submitAttendance(any(), any())).thenAnswer(
          (_) async => response(
            outcome: 'SUPERSEDED',
            updatedAt: null,
            absences: const [
              AttendanceAbsenceAck(
                studentId: 's9',
                updatedAt: '2026-06-15T10:00:00.000Z',
              ),
            ],
          ),
        );

        expect(await adoptedToken(), epochOf('2026-06-15T10:00:00.000Z'));
      },
    );

    test('session.updatedAt prime dès que le serveur l\'émettra', () async {
      when(() => api.submitAttendance(any(), any())).thenAnswer(
        (_) async => response(
          outcome: 'SUPERSEDED',
          updatedAt: '2026-06-15T11:00:00.000Z',
        ),
      );

      expect(await adoptedToken(), epochOf('2026-06-15T11:00:00.000Z'));
    });
  });
}
