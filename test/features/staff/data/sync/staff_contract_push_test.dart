import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_contract_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_contract_sync_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_contract_write_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_dao.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_contract_input_mapper.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_contract_correction_outbox_handler.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_contract_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_contract_outbox_handler.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_contract_push_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_member_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_sync_api.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_draft.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';
import '../../staff_fixtures.dart';

class _MockApi extends Mock implements StaffSyncApi {}

DioException _http(int status, {String? detailCode}) => DioException(
  requestOptions: RequestOptions(path: '/'),
  response: Response(
    requestOptions: RequestOptions(path: '/'),
    statusCode: status,
    data: detailCode == null ? null : {'detailCode': detailCode},
  ),
);

const _permanent = StaffContractDraft(
  kind: StaffContractKind.permanent,
  effectiveFrom: '2026-10-01',
  amount: '320',
  currency: 'usd',
  secopeNumber: 'ignoré',
);

StaffContractInputDto _input(String id, [StaffContractDraft d = _permanent]) =>
    StaffContractInputMapper.of(
      d,
      id: id,
      recordedAt: '2026-09-29T08:00:00.000Z',
    )!;

OutboxEntry _entry(String id, String type, Map<String, dynamic> json) =>
    OutboxEntry(
      id: id,
      aggregateType: type,
      aggregateId: 'm-1',
      operation: OutboxOperation.create,
      payload: jsonEncode(json),
      schoolId: 's-1',
      createdAt: 1,
    );

void main() {
  late Database db;
  late _MockApi api;
  late StaffContractWriteDao writer;
  final user = CurrentUserContext()..set('u-1', schoolId: 's-1');

  setUp(() async {
    db = await openFullOfflineDb();
    api = _MockApi();
    writer = StaffContractWriteDao(db);
  });
  tearDown(() async => db.close());

  Future<void> seedAckedMember() => StaffMemberDao(db).applyPulled(
    [StaffMemberDeltaDto.tryParse(staffMemberJson('m-1'))!],
    schoolId: 's-1',
    nowMs: 1,
  );

  Future<void> seedSyncedContract(String id) =>
      StaffContractDao(db).applyPulled(
        [StaffContractDeltaDto.tryParse(staffContractJson(id))!],
        schoolId: 's-1',
        nowMs: 1,
      );

  Future<Map<String, Object?>?> row(String id) async {
    final rows = await db.query(
      'staff_contracts',
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : rows.single;
  }

  group('mapper et payload', () {
    test('chaque champ étranger au statut part à null, devise normalisée', () {
      final input = _input('c-1');
      expect(input.amountInCents, 32000);
      expect(input.currency, 'USD');
      expect(input.secopeNumber, isNull);
      expect(input.bonusInCents, isNull);

      final conventionne = _input(
        'c-2',
        const StaffContractDraft(
          kind: StaffContractKind.conventionne,
          effectiveFrom: '2026-10-01',
          amount: '999',
          secopeNumber: ' S-42 ',
        ),
      );
      expect(conventionne.amountInCents, isNull);
      expect(conventionne.currency, isNull);
      expect(conventionne.secopeNumber, 'S-42');
    });

    test('un brouillon incomplet ne fabrique rien', () {
      expect(
        StaffContractInputMapper.of(
          const StaffContractDraft(kind: StaffContractKind.permanent),
          id: 'c-1',
          recordedAt: 'x',
        ),
        isNull,
      );
    });

    test('pose et correction se relisent à l identique', () {
      final pose = StaffContractSyncRequestDto(
        staffMemberId: 'm-1',
        contract: _input('c-1'),
        authorId: 'u-1',
      );
      expect(
        StaffContractSyncRequestDto.tryParse(
          jsonDecode(jsonEncode(pose.toJson())),
        )!.toJson(),
        pose.toJson(),
      );
      final correction = StaffContractCorrectionRequestDto(
        correctionId: 'k-1',
        contractId: 'c-1',
        staffMemberId: 'm-1',
        correctedAt: '2026-09-29T09:00:00.000Z',
        reason: 'Mauvais montant',
        replacement: _input('c-2'),
        authorId: 'u-1',
      );
      expect(
        StaffContractCorrectionRequestDto.tryParse(
          jsonDecode(jsonEncode(correction.toJson())),
        )!.toJson(),
        correction.toJson(),
      );
      expect(correction.toBody().containsKey('staffMemberId'), isFalse);
    });

    test('un remplaçant illisible ne se lit pas « annuler seulement »', () {
      final raw = {
        'correctionId': 'k-1',
        'contractId': 'c-1',
        'staffMemberId': 'm-1',
        'correctedAt': 'x',
        'authorId': 'u-1',
        'replacement': {'id': 'c-2'},
      };
      expect(StaffContractCorrectionRequestDto.tryParse(raw), isNull);
    });
  });

  group('écritures locales', () {
    test('poser écrit la période en attente et son entrée', () async {
      await writer.addContract(
        request: StaffContractSyncRequestDto(
          staffMemberId: 'm-1',
          contract: _input('c-1'),
          authorId: 'u-1',
        ),
        schoolId: 's-1',
        nowMs: 1,
      );

      expect((await row('c-1'))!['sync_status'], 'PENDING_SYNC');
      final entries = await OutboxDao(db).pendingAll();
      expect(entries.map((e) => e.id), ['STAFF_CONTRACT:c-1']);
    });

    test(
      'corriger marque l original, pose le remplaçant, UNE entrée',
      () async {
        await seedSyncedContract('c-1');
        await writer.correct(
          request: StaffContractCorrectionRequestDto(
            correctionId: 'k-1',
            contractId: 'c-1',
            staffMemberId: 'm-1',
            correctedAt: 'x',
            replacement: _input('c-2'),
            authorId: 'u-1',
          ),
          schoolId: 's-1',
          nowMs: 2,
        );

        final original = (await row('c-1'))!;
        expect(original['correction_pending_id'], 'k-1');
        expect(original['corrected_at'], isNull);
        expect((await row('c-2'))!['sync_status'], 'PENDING_SYNC');
        expect((await OutboxDao(db).pendingAll()).map((e) => e.id), [
          'STAFF_CONTRACT_CORRECTION:k-1',
        ]);

        // Une descente de la période n'efface pas la correction en vol.
        await seedSyncedContract('c-1');
        expect((await row('c-1'))!['correction_pending_id'], 'k-1');
      },
    );
  });

  group('handler de pose', () {
    late StaffContractOutboxHandler handler;
    late Map<String, dynamic> payload;

    setUp(() async {
      handler = StaffContractOutboxHandler(
        api: api,
        dao: StaffContractSyncDao(db),
        members: StaffMemberDao(db),
        currentUser: user,
        extras: const {},
        now: () => 42,
      );
      final request = StaffContractSyncRequestDto(
        staffMemberId: 'm-1',
        contract: _input('c-1'),
        authorId: 'u-1',
      );
      payload = request.toJson();
      await writer.addContract(request: request, schoolId: 's-1', nowMs: 1);
    });

    Future<OutboxDispatchResult> dispatch() => handler.dispatch(
      _entry('STAFF_CONTRACT:c-1', 'STAFF_CONTRACT', payload),
    );

    test(
      'attend la fiche tant qu elle n est pas accusée, sans appel',
      () async {
        // Sans fiche du tout (purgée), la pose le dit au lieu d'attendre.
        expect((await dispatch()).outcome, OutboxDispatchOutcome.failed);
        expect(
          (await row('c-1'))!['sync_error_code'],
          StaffContractOutboxHandler.memberGoneCode,
        );
        await db.insert('staff_members', {
          'id': 'm-1',
          'school_id': 's-1',
          'last_name': 'K',
          'first_name': 'J',
          'category': 'TEACHER',
          'sync_status': 'PENDING_SYNC',
        });
        expect((await dispatch()).outcome, OutboxDispatchOutcome.blocked);
        verifyNever(() => api.submitStaffContract(any(), any(), any()));
      },
    );

    test('accusé : la période devient celle du serveur', () async {
      await seedAckedMember();
      when(() => api.submitStaffContract(any(), any(), any())).thenAnswer(
        (_) async => StaffContractSyncResponseDto.fromJson({
          'contract': staffContractJson('c-1'),
        }),
      );

      expect((await dispatch()).outcome, OutboxDispatchOutcome.acked);
      expect((await row('c-1'))!['sync_status'], 'SYNCED');
    });

    test('409 STAFF_MEMBER_NOT_YET_SYNCED attend, 422 refuse', () async {
      await seedAckedMember();
      when(
        () => api.submitStaffContract(any(), any(), any()),
      ).thenThrow(_http(409, detailCode: 'STAFF_MEMBER_NOT_YET_SYNCED'));
      expect((await dispatch()).outcome, OutboxDispatchOutcome.blocked);

      when(
        () => api.submitStaffContract(any(), any(), any()),
      ).thenThrow(_http(422, detailCode: 'AMOUNT_REQUIRED'));
      expect((await dispatch()).outcome, OutboxDispatchOutcome.failed);
      final rejected = (await row('c-1'))!;
      expect(rejected['sync_status'], 'SYNC_ERROR');
      expect(rejected['sync_error_code'], 'AMOUNT_REQUIRED');
    });
  });

  group('handler de correction', () {
    late StaffContractCorrectionOutboxHandler handler;
    late Map<String, dynamic> payload;

    Future<void> correct() async {
      final request = StaffContractCorrectionRequestDto(
        correctionId: 'k-1',
        contractId: 'c-1',
        staffMemberId: 'm-1',
        correctedAt: '2026-09-29T09:00:00.000Z',
        reason: 'Mauvais montant',
        replacement: _input('c-2'),
        authorId: 'u-1',
      );
      payload = request.toJson();
      await writer.correct(request: request, schoolId: 's-1', nowMs: 2);
    }

    setUp(() {
      handler = StaffContractCorrectionOutboxHandler(
        api: api,
        dao: StaffContractSyncDao(db),
        currentUser: user,
        extras: const {},
        now: () => 42,
      );
    });

    Future<OutboxDispatchResult> dispatch() => handler.dispatch(
      _entry(
        'STAFF_CONTRACT_CORRECTION:k-1',
        'STAFF_CONTRACT_CORRECTION',
        payload,
      ),
    );

    test('attend que la période corrigée soit accusée', () async {
      await writer.addContract(
        request: StaffContractSyncRequestDto(
          staffMemberId: 'm-1',
          contract: _input('c-1'),
          authorId: 'u-1',
        ),
        schoolId: 's-1',
        nowMs: 1,
      );
      await correct();

      expect((await dispatch()).outcome, OutboxDispatchOutcome.blocked);
      verifyNever(() => api.correctStaffContract(any(), any()));
    });

    test(
      'accusé : corrigée datée, remplaçant accusé, marqueur tombé',
      () async {
        await seedSyncedContract('c-1');
        await correct();
        when(() => api.correctStaffContract(any(), any())).thenAnswer(
          (_) async => StaffContractCorrectionResponseDto.fromJson({
            'corrected': {
              ...staffContractJson('c-1'),
              'correctedAt': '2026-09-29T09:00:01Z',
            },
            'replacement': staffContractJson('c-2'),
          }),
        );

        expect((await dispatch()).outcome, OutboxDispatchOutcome.acked);
        final original = (await row('c-1'))!;
        expect(original['corrected_at'], isNotNull);
        expect(original['correction_pending_id'], isNull);
        expect((await row('c-2'))!['sync_status'], 'SYNCED');
      },
    );

    test('refus après accusé perdu : le remplaçant descendu reste', () async {
      await seedSyncedContract('c-1');
      await correct();
      // La réponse s'est perdue ; la descente a rangé le remplaçant réel et
      // daté la correction.
      await StaffContractDao(db).applyPulled(
        [
          StaffContractDeltaDto.tryParse({
            ...staffContractJson('c-1'),
            'correctedAt': '2026-09-29T09:00:01Z',
          })!,
          StaffContractDeltaDto.tryParse(staffContractJson('c-2'))!,
        ],
        schoolId: 's-1',
        nowMs: 3,
      );
      when(() => api.correctStaffContract(any(), any())).thenThrow(_http(403));

      expect((await dispatch()).outcome, OutboxDispatchOutcome.failed);
      expect((await row('c-2'))!['sync_status'], 'SYNCED');
      expect((await row('c-1'))!['sync_error'], isNull);
    });

    test('410 : la période purgée quitte le poste', () async {
      await seedSyncedContract('c-1');
      await correct();
      when(() => api.correctStaffContract(any(), any())).thenThrow(_http(410));

      expect((await dispatch()).outcome, OutboxDispatchOutcome.acked);
      expect(await row('c-1'), isNull);
      expect(await row('c-2'), isNull);
    });

    test('refus : l original revient, le remplaçant s efface', () async {
      await seedSyncedContract('c-1');
      await correct();
      when(
        () => api.correctStaffContract(any(), any()),
      ).thenThrow(_http(422, detailCode: 'INVALID_CONTRACT'));

      expect((await dispatch()).outcome, OutboxDispatchOutcome.failed);
      final original = (await row('c-1'))!;
      expect(original['correction_pending_id'], isNull);
      expect(original['sync_error_code'], 'INVALID_CONTRACT');
      expect(await row('c-2'), isNull);
    });
  });
}
