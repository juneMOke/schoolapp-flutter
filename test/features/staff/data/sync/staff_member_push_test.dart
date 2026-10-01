import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_sync_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_write_dao.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_member_input_mapper.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_member_outbox_handler.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_member_push_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_sync_api.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_diploma.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member_draft.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';
import '../../staff_fixtures.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

class _MockApi extends Mock implements StaffSyncApi {}

const _draft = StaffMemberDraft(
  id: 'm-1',
  lastName: ' Kalala ',
  middleName: 'Mutombo',
  firstName: 'Didier',
  sex: StaffSex.male,
  phone: '0824401276',
  email: '  ',
  city: 'Kinshasa',
  district: 'Funa',
  municipality: 'Kalamu',
  neighborhood: 'Matonge',
  category: StaffCategory.administrative,
  jobTitle: 'Censeur',
  entryDate: '2023-09-15',
  branches: ['Mathématiques'],
  diplomas: [
    StaffDiploma(level: 'L2 — Licence', title: 'Pédagogie'),
    StaffDiploma(level: '', title: ''),
  ],
);

DioException _http(int status, {String? detailCode}) => DioException(
  requestOptions: RequestOptions(path: '/'),
  response: Response(
    requestOptions: RequestOptions(path: '/'),
    statusCode: status,
    data: detailCode == null ? null : {'detailCode': detailCode},
  ),
);

void main() {
  late Database db;
  late _MockApi api;
  late StaffMemberWriteDao writer;
  late StaffMemberHandlerHarness h;

  setUp(() async {
    db = await openFullOfflineDb();
    api = _MockApi();
    writer = StaffMemberWriteDao(db);
    h = StaffMemberHandlerHarness(db, api);
  });
  tearDown(() async => db.close());

  StaffMemberSyncRequestDto request(String clientUpdatedAt) =>
      StaffMemberSyncRequestDto(
        staffMember: StaffMemberInputMapper.of(
          _draft,
          clientUpdatedAt: clientUpdatedAt,
        )!,
        authorId: 'u-1',
      );

  test('le mapper rogne, normalise et écarte ce qui ne part pas', () {
    final input = request('2026-09-29T08:00:00.000Z').staffMember;

    expect(input.lastName, 'Kalala');
    expect(input.phoneNumber, '+243824401276');
    expect(input.email, isNull);
    // Un administratif ne porte pas de matières ; une ligne vide ne part pas.
    expect(input.branches, isEmpty);
    expect(input.diplomas.single.title, 'Pédagogie');
  });

  test('le payload figé se relit à l identique (chemin du push)', () {
    final sent = request('2026-09-29T08:00:00.000Z');
    final reread = StaffMemberSyncRequestDto.tryParse(
      jsonDecode(jsonEncode(sent.toJson())),
    )!;

    expect(reread.toJson(), sent.toJson());
    expect(sent.toJson()['authorId'], 'u-1');
  });

  test(
    'enregistrer écrit la fiche en attente et UNE entrée par agent',
    () async {
      await writer.save(
        request: request('2026-09-29T08:00:00.000Z'),
        schoolId: 's-1',
        nowMs: 1,
      );
      await writer.save(
        request: request('2026-09-29T09:00:00.000Z'),
        schoolId: 's-1',
        nowMs: 2,
      );

      final member = (await StaffMemberDao(db).find('m-1'))!.toEntity();
      expect(member.syncState, RecordSyncState.pending);
      expect(member.staffNumber, isNull);
      final entries = await OutboxDao(db).pendingAll();
      expect(entries.map((e) => e.id), ['STAFF_MEMBER:m-1']);
      expect(entries.single.payload, contains('2026-09-29T09:00:00.000Z'));
    },
  );

  group('handler', () {
    Future<OutboxDispatchResult> dispatch(String clientUpdatedAt) async {
      final sent = request(clientUpdatedAt);
      await writer.save(request: sent, schoolId: 's-1', nowMs: 1);
      return h.handler.dispatch(
        OutboxEntry(
          id: 'STAFF_MEMBER:m-1',
          aggregateType: 'STAFF_MEMBER',
          aggregateId: 'm-1',
          operation: OutboxOperation.upsert,
          payload: jsonEncode(sent.toJson()),
          schoolId: 's-1',
          createdAt: 1,
        ),
      );
    }

    test('accusé : matricule posé, fiche synchronisée', () async {
      when(() => api.submitStaffMember(any(), any())).thenAnswer(
        (_) async => StaffMemberSyncResponseDto.fromJson({
          'staffMember': staffMemberJson('m-1', staffNumber: 'CF-AG-0048'),
          'lwwOutcome': 'APPLIED',
        }),
      );

      final result = await dispatch('2026-09-29T08:00:00.000Z');

      expect(result.outcome, OutboxDispatchOutcome.acked);
      final member = (await StaffMemberDao(db).find('m-1'))!.toEntity();
      expect(member.staffNumber, 'CF-AG-0048');
      expect(member.syncState, RecordSyncState.synced);
    });

    test('une saisie plus récente pendant le vol n est pas écrasée', () async {
      when(() => api.submitStaffMember(any(), any())).thenAnswer((_) async {
        // Pendant le vol, la fiche est modifiée sur le poste.
        await writer.save(
          request: request('2026-09-29T09:30:00.000Z'),
          schoolId: 's-1',
          nowMs: 5,
        );
        return StaffMemberSyncResponseDto.fromJson({
          'staffMember': staffMemberJson(
            'm-1',
            firstName: 'Ancien',
            staffNumber: 'CF-AG-0048',
          ),
          'lwwOutcome': 'APPLIED',
        });
      });

      await dispatch('2026-09-29T08:00:00.000Z');

      final member = (await StaffMemberDao(db).find('m-1'))!.toEntity();
      expect(member.firstName, 'Didier');
      expect(member.staffNumber, 'CF-AG-0048');
      expect(member.syncState, RecordSyncState.pending);
    });

    test('refus 422 : fiche refusée, entrée en échec', () async {
      when(
        () => api.submitStaffMember(any(), any()),
      ).thenThrow(_http(422, detailCode: 'INVALID_PHONE_NUMBER'));

      final result = await dispatch('2026-09-29T08:00:00.000Z');

      expect(result.outcome, OutboxDispatchOutcome.failed);
      final row = (await db.query('staff_members')).single;
      expect(row['sync_status'], 'SYNC_ERROR');
      expect(row['sync_error_code'], 'INVALID_PHONE_NUMBER');
    });

    test('transitoires et 409 sans code se rejouent', () async {
      for (final status in [503, 429, 409]) {
        when(
          () => api.submitStaffMember(any(), any()),
        ).thenThrow(_http(status));
        expect(
          (await dispatch('2026-09-29T08:00:00.000Z')).outcome,
          OutboxDispatchOutcome.retry,
        );
      }
    });

    test('410 : la fiche purgée s efface du poste', () async {
      when(() => api.submitStaffMember(any(), any())).thenThrow(_http(410));

      final result = await dispatch('2026-09-29T08:00:00.000Z');

      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect(await db.query('staff_members'), isEmpty);
    });

    test('une fiche d une autre école attend sa session, sans appel', () async {
      h.user.set('u-1', schoolId: 'autre');

      final result = await dispatch('2026-09-29T08:00:00.000Z');

      expect(result.outcome, OutboxDispatchOutcome.blocked);
      verifyNever(() => api.submitStaffMember(any(), any()));
    });

    test('un payload illisible échoue sans appel', () async {
      final result = await h.handler.dispatch(
        const OutboxEntry(
          id: 'STAFF_MEMBER:m-1',
          aggregateType: 'STAFF_MEMBER',
          aggregateId: 'm-1',
          operation: OutboxOperation.upsert,
          payload: '{"staffMember": {"id": "m-1"}}',
          schoolId: 's-1',
          createdAt: 1,
        ),
      );

      expect(result.outcome, OutboxDispatchOutcome.failed);
      verifyNever(() => api.submitStaffMember(any(), any()));
    });
  });
}

class StaffMemberHandlerHarness {
  final CurrentUserContext user = CurrentUserContext()
    ..set('u-1', schoolId: 's-1');
  late final StaffMemberOutboxHandler handler;

  StaffMemberHandlerHarness(Database db, StaffSyncApi api) {
    handler = StaffMemberOutboxHandler(
      api: api,
      dao: StaffMemberSyncDao(db),
      currentUser: user,
      extras: const {},
      now: () => 42,
    );
  }
}
