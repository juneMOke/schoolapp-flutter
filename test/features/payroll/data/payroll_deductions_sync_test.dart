import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/staff/local/payroll_settings_seed.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_deduction_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_deduction_type_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_gesture_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_outbox.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_deduction_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_deduction_outbox_handlers.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_gesture_outbox_handler.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_sync_api.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_write_requests.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction_codes.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../offline_full_db.dart';

class _MockApi extends Mock implements PayrollSyncApi {}

const _school = 's-1';
const _month = '2026-10';

DioException _http(int status, String code) => DioException(
  requestOptions: RequestOptions(path: '/'),
  response: Response(
    requestOptions: RequestOptions(path: '/'),
    statusCode: status,
    data: {'detailCode': code, 'detail': code},
  ),
);

PayrollDeductionTypeRequestDto _type({
  String id = 't-1',
  String label = 'Cartes',
  String at = '2026-10-20T09:00:00Z',
  bool archived = false,
}) => PayrollDeductionTypeRequestDto(
  id: id,
  label: label,
  sortOrder: 10,
  archived: archived,
  clientUpdatedAt: at,
  authorId: 'u-1',
);

PayrollDeductionRequestDto _saisie({
  String type = 't-1',
  int amount = 500,
  String at = '2026-10-21T09:00:00Z',
}) => PayrollDeductionRequestDto(
  month: _month,
  staffMemberId: 'm-1',
  deductionTypeId: type,
  amountInCents: amount,
  currency: 'USD',
  clientUpdatedAt: at,
  authorId: 'u-1',
);

PayrollDeductionTypeSeed _seed(String id, {String label = 'Cartes'}) => (
  id: id,
  label: label,
  sortOrder: 10,
  archived: false,
  clientUpdatedAt: '2026-10-20T09:00:00Z',
);

PayrollDeductionDto _server(int amount, {String type = 't-1'}) =>
    PayrollDeductionDto(
      staffMemberId: 'm-1',
      deductionTypeId: type,
      amountInCents: amount,
      currency: 'USD',
      clientUpdatedAt: '2026-10-22T09:00:00Z',
    );

void main() {
  late Database db;
  late _MockApi api;
  late OutboxDao outbox;
  late PayrollDeductionTypeDao types;
  late PayrollDeductionDao deductions;
  final user = CurrentUserContext()..set('u-1', schoolId: _school);

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() async {
    db = await openFullOfflineDb();
    api = _MockApi();
    outbox = OutboxDao(db);
    types = PayrollDeductionTypeDao(db);
    deductions = PayrollDeductionDao(db);
  });
  tearDown(() => db.close());

  PayrollDeductionTypeOutboxHandler typeHandler() =>
      PayrollDeductionTypeOutboxHandler(
        api: api,
        dao: types,
        outbox: outbox,
        currentUser: user,
        extras: const {},
      );

  PayrollDeductionOutboxHandler saisieHandler() =>
      PayrollDeductionOutboxHandler(
        api: api,
        dao: deductions,
        types: types,
        outbox: outbox,
        currentUser: user,
        extras: const {},
      );

  Future<void> saveType(
    PayrollDeductionTypeRequestDto request, {
    int at = 10,
  }) => types.saveAll([request], schoolId: _school, nowMs: at);

  Future<void> saveSaisie(PayrollDeductionRequestDto request, {int at = 20}) =>
      deductions.saveWithVariables(
        null,
        [request],
        schoolId: _school,
        nowMs: at,
      );

  Future<OutboxEntry> entryOf(String type) async =>
      (await outbox.pendingAll()).firstWhere((e) => e.aggregateType == type);

  Future<PayrollDeductionTypeRequestDto> known() async {
    final request = _type();
    await saveType(request);
    await types.acknowledge(request, schoolId: _school, nowMs: 0);
    await db.update(PayrollDeductionTypeDao.table, {'acked_at': null});
    await db.delete(OutboxDao.table);
    return request;
  }

  group('catalogue au socle', () {
    test('la liste fait foi : ajoute, met à jour, retire le connu', () async {
      await types.applySeed(
        [_seed('t-1'), _seed('t-2')],
        schoolId: _school,
        nowMs: 1,
      );
      await types.applySeed(
        [_seed('t-1', label: 'Badges')],
        schoolId: _school,
        nowMs: 2,
      );

      final all = await types.forSchool(_school);
      expect(all.map((t) => t.id), ['t-1']);
      expect(all.single.label, 'Badges');
    });

    test('une création jamais reçue n\'est pas purgée', () async {
      await saveType(_type(id: 't-new'));

      await types.applySeed(const [], schoolId: _school, nowMs: 2);

      expect((await types.forSchool(_school)).single.id, 't-new');
    });

    test('une création refusée reste affichée', () async {
      await saveType(_type(id: 't-new'));
      await types.refuse(
        _type(id: 't-new'),
        schoolId: _school,
        code: PayrollDeductionCodes.labelTaken,
        reason: 'pris',
      );
      await db.delete(OutboxDao.table);

      await types.applySeed(const [], schoolId: _school, nowMs: 2);

      final type = (await types.forSchool(_school)).single;
      expect(type.syncState, RecordSyncState.failed);
      expect(type.syncErrorCode, PayrollDeductionCodes.labelTaken);
    });

    test('une écriture en file n\'est pas écrasée', () async {
      await known();
      await saveType(_type(label: 'Local', at: '2026-10-25T09:00:00Z'));

      await types.applySeed(
        [_seed('t-1', label: 'Serveur')],
        schoolId: _school,
        nowMs: 2,
      );

      expect((await types.forSchool(_school)).single.label, 'Local');
    });

    test('champ absent : pas de liste ; illisible : pas de liste', () {
      Map<String, Object?> raw(Object? types) => {
        'monthlyHoursDivisor': 173,
        'overtimeMultiplierPermille': 1000,
        'allowanceEligibleKinds': const [],
        'currencyRules': const [],
        'deductionTypes': types,
      };

      expect(PayrollSettingsSeed.tryParse(raw(null))!.deductionTypes, isNull);
      expect(PayrollSettingsSeed.tryParse(raw([1]))!.deductionTypes, isNull);
      expect(PayrollSettingsSeed.tryParse(raw([]))!.deductionTypes, isEmpty);
      expect(
        PayrollSettingsSeed.tryParse(
          raw([
            {'id': 'T-1', 'label': 'Cartes', 'sortOrder': 10},
          ]),
        )!.deductionTypes!.single.id,
        't-1',
      );
    });
  });

  group('saisies à la descente', () {
    Future<void> pull(List<PayrollDeductionDto>? items) => db.transaction(
      (txn) => PayrollDeductionDao.applyServer(
        txn,
        _month,
        items,
        schoolId: _school,
        nowMs: 5,
      ),
    );

    Future<List<int>> amounts() async {
      final month = (await deductions.forSchool(_school))[_month];
      return [
        for (final list in (month ?? const {}).values)
          for (final entry in list) entry.amountInCents,
      ];
    }

    test('remplace : une ligne absente du serveur disparaît', () async {
      await pull([_server(500), _server(300, type: 't-2')]);
      await pull([_server(700)]);

      expect(await amounts(), [700]);
    });

    test('une saisie à 0 descend et reste', () async {
      await pull([_server(0)]);

      expect(await amounts(), [0]);
    });

    test('champ absent (accusé de geste) : rien ne bouge', () async {
      await pull([_server(500)]);
      await pull(null);

      expect(await amounts(), [500]);
    });

    test('une saisie en file n\'est ni écrasée ni retirée', () async {
      await saveSaisie(_saisie(amount: 900));

      await pull([_server(500)]);
      expect(await amounts(), [900]);

      await pull(const []);
      expect(await amounts(), [900]);
    });

    test('refusée sans valeur au serveur, elle reste hors calcul', () async {
      await saveSaisie(_saisie());
      await deductions.refuse(
        _saisie(),
        schoolId: _school,
        code: PayrollDeductionCodes.archived,
      );
      await db.delete(OutboxDao.table);

      await pull(const []);

      final entry = (await deductions.forSchool(
        _school,
      ))[_month]!['m-1']!.single;
      expect(entry.syncState, RecordSyncState.failed);
      expect(entry.syncErrorCode, PayrollDeductionCodes.archived);
      expect(entry.counted, isNull);
    });

    test(
      'une modification refusée laisse compter la valeur du serveur',
      () async {
        await pull([_server(300)]);
        await saveSaisie(_saisie(amount: 800));
        await deductions.refuse(_saisie(amount: 800), schoolId: _school);
        await db.delete(OutboxDao.table);

        final entry = (await deductions.forSchool(
          _school,
        ))[_month]!['m-1']!.single;
        expect(entry.syncState, RecordSyncState.failed);
        expect(entry.amountInCents, 800);
        expect(entry.counted!.amountInCents, 300);
      },
    );

    test('la lecture du refus revient à la valeur du serveur', () async {
      await pull([_server(300)]);
      await saveSaisie(_saisie(amount: 800));
      await deductions.refuse(_saisie(amount: 800), schoolId: _school);
      await db.update(OutboxDao.table, {
        'status': OutboxStatus.syncError.dbValue,
      });
      final refused = (await deductions.forSchool(
        _school,
      ))[_month]!['m-1']!.single;

      await deductions.dismiss(_month, refused, schoolId: _school);

      final entry = (await deductions.forSchool(
        _school,
      ))[_month]!['m-1']!.single;
      expect(entry.amountInCents, 300);
      expect(entry.syncState, RecordSyncState.synced);
      expect(await db.query(OutboxDao.table), isEmpty);
    });

    test('un refus se garde même si la descente repasse', () async {
      await saveSaisie(_saisie());
      await deductions.refuse(_saisie(), schoolId: _school, code: 'X');
      await db.delete(OutboxDao.table);

      await pull([_server(300)]);

      final entry = (await deductions.forSchool(
        _school,
      ))[_month]!['m-1']!.single;
      expect(entry.syncState, RecordSyncState.failed);
      expect(entry.counted!.amountInCents, 300);
    });

    test('une saisie en file garde la valeur du serveur en réserve', () async {
      await saveSaisie(_saisie(amount: 900));

      await pull([_server(500)]);

      final entry = (await deductions.forSchool(
        _school,
      ))[_month]!['m-1']!.single;
      expect(entry.amountInCents, 900);
      expect(entry.serverAmountInCents, 500);
    });

    test('un accusé tout frais résiste à une descente lue avant lui', () async {
      await saveSaisie(_saisie(amount: 900));
      await deductions.acknowledge(
        _saisie(amount: 900),
        schoolId: _school,
        nowMs: 5,
      );

      await pull(const []);
      await pull([_server(100)]);

      final entry = (await deductions.forSchool(
        _school,
      ))[_month]!['m-1']!.single;
      expect(entry.amountInCents, 900);
    });

    test('une saisie illisible : la paie ne remplace rien', () {
      final dto = PayrollDto.tryParse({
        'id': 'p',
        'month': _month,
        'status': 'DRAFT',
        'deductions': [
          {'staffMemberId': 'm-1'},
        ],
      })!;

      expect(dto.deductions, isNull);
    });

    test('la paie descendue range ses saisies', () async {
      await PayrollDao(db).apply(
        [
          PayrollDto.tryParse({
            'id': 'p',
            'month': _month,
            'status': 'DRAFT',
            'deductions': [
              {
                'staffMemberId': 'm-1',
                'deductionTypeId': 'T-1',
                'amountInCents': 500,
                'currency': 'USD',
                'clientUpdatedAt': '2026-10-22T09:00:00Z',
                'version': 3,
              },
            ],
          })!,
        ],
        schoolId: _school,
        nowMs: 1,
      );

      final entry = (await deductions.forSchool(
        _school,
      ))[_month]!['m-1']!.single;
      expect(entry.deductionTypeId, 't-1');
    });
  });

  group('envoi d\'une rubrique', () {
    test('remplacée : acquittée sans envoi', () async {
      await saveType(_type());
      final older = await entryOf(PayrollOutbox.deductionType);
      await saveType(
        _type(label: 'Badges', at: '2026-10-25T09:00:00Z'),
        at: 20,
      );

      final result = await typeHandler().dispatch(older);

      expect(result.outcome, OutboxDispatchOutcome.acked);
      verifyNever(() => api.submitDeductionType(any(), any()));
    });

    test('en file, elle se lit en attente, pas refusée', () async {
      await saveType(_type());

      expect(
        (await types.forSchool(_school)).single.syncState,
        RecordSyncState.pending,
      );
    });

    test('accusée, le serveur la connaît', () async {
      when(
        () => api.submitDeductionType(any(), any()),
      ).thenAnswer((_) async => {});
      await saveType(_type());

      final result = await typeHandler().dispatch(
        await entryOf(PayrollOutbox.deductionType),
      );

      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect(await types.isServerKnown(_school, 't-1'), isTrue);
      expect(
        (await types.forSchool(_school)).single.syncState,
        RecordSyncState.synced,
      );
    });

    test('libellé pris : refusée, avec son code', () async {
      when(
        () => api.submitDeductionType(any(), any()),
      ).thenThrow(_http(422, PayrollDeductionCodes.labelTaken));
      await saveType(_type());

      final result = await typeHandler().dispatch(
        await entryOf(PayrollOutbox.deductionType),
      );

      expect(result.outcome, OutboxDispatchOutcome.failed);
      expect(
        (await types.forSchool(_school)).single.syncErrorCode,
        PayrollDeductionCodes.labelTaken,
      );
    });

    test('pierre tombale : elle disparaît, sans rejeu', () async {
      when(
        () => api.submitDeductionType(any(), any()),
      ).thenThrow(_http(410, PayrollDeductionCodes.tombstoned));
      await saveType(_type());

      final result = await typeHandler().dispatch(
        await entryOf(PayrollOutbox.deductionType),
      );

      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect(await types.forSchool(_school), isEmpty);
    });
  });

  group('envoi d\'une saisie', () {
    test('attend la rubrique posée avant elle', () async {
      await saveType(_type());
      await saveSaisie(_saisie());

      final result = await saisieHandler().dispatch(
        await entryOf(PayrollOutbox.deduction),
      );

      expect(result.outcome, OutboxDispatchOutcome.blocked);
      verifyNever(() => api.submitDeduction(any(), any()));
    });

    test('rubrique acceptée : la saisie part', () async {
      when(() => api.submitDeduction(any(), any())).thenAnswer((_) async => {});
      await known();
      await saveSaisie(_saisie());

      final result = await saisieHandler().dispatch(
        await entryOf(PayrollOutbox.deduction),
      );

      expect(result.outcome, OutboxDispatchOutcome.acked);
    });

    test('rubrique refusée : la saisie échoue en la nommant', () async {
      await saveType(_type());
      await saveSaisie(_saisie());
      await types.refuse(_type(), schoolId: _school, code: 'X');
      await db.delete(
        OutboxDao.table,
        where: 'aggregate_type = ?',
        whereArgs: [PayrollOutbox.deductionType],
      );

      final result = await saisieHandler().dispatch(
        await entryOf(PayrollOutbox.deduction),
      );

      expect(result.outcome, OutboxDispatchOutcome.failed);
      verifyNever(() => api.submitDeduction(any(), any()));
      final entry = (await deductions.forSchool(
        _school,
      ))[_month]!['m-1']!.single;
      expect(entry.syncErrorCode, PayrollDeductionCodes.typeRefused);
    });

    test('409 d\'attente : bloquée, sans tentative', () async {
      when(
        () => api.submitDeduction(any(), any()),
      ).thenThrow(_http(409, PayrollDeductionCodes.typeNotYetSynced));
      await saveSaisie(_saisie());

      final result = await saisieHandler().dispatch(
        await entryOf(PayrollOutbox.deduction),
      );

      expect(result.outcome, OutboxDispatchOutcome.blocked);
    });

    test('410 : acquittée, gardée hors calcul avec son motif', () async {
      when(
        () => api.submitDeduction(any(), any()),
      ).thenThrow(_http(410, PayrollDeductionCodes.tombstoned));
      await saveSaisie(_saisie());

      final result = await saisieHandler().dispatch(
        await entryOf(PayrollOutbox.deduction),
      );

      expect(result.outcome, OutboxDispatchOutcome.acked);
      final entry = (await deductions.forSchool(
        _school,
      ))[_month]!['m-1']!.single;
      expect(entry.syncState, RecordSyncState.failed);
      expect(entry.syncErrorCode, PayrollDeductionCodes.tombstoned);
    });

    test('un accusé SUPERSEDED range la valeur retenue', () async {
      when(() => api.submitDeduction(any(), any())).thenAnswer(
        (_) async => {
          'lwwOutcome': 'SUPERSEDED',
          'deduction': {
            'staffMemberId': 'm-1',
            'deductionTypeId': 't-1',
            'amountInCents': 777,
            'currency': 'USD',
            'clientUpdatedAt': '2026-10-22T09:00:00Z',
          },
        },
      );
      await saveSaisie(_saisie());

      await saisieHandler().dispatch(await entryOf(PayrollOutbox.deduction));

      final entry = (await deductions.forSchool(
        _school,
      ))[_month]!['m-1']!.single;
      expect(entry.amountInCents, 777);
      expect(entry.serverAmountInCents, 777);
    });

    test(
      'remplacée : acquittée sans envoi, sans boucler sur un refus',
      () async {
        await saveSaisie(_saisie(amount: 700));
        final older = await entryOf(PayrollOutbox.deduction);
        await saveSaisie(
          _saisie(amount: 800, at: '2026-10-22T09:00:00Z'),
          at: 30,
        );

        final result = await saisieHandler().dispatch(older);

        expect(result.outcome, OutboxDispatchOutcome.acked);
        verifyNever(() => api.submitDeduction(any(), any()));
      },
    );

    test('devise refusée : le code est rangé sur la saisie', () async {
      when(
        () => api.submitDeduction(any(), any()),
      ).thenThrow(_http(422, PayrollDeductionCodes.currencyMismatch));
      await saveSaisie(_saisie());

      final result = await saisieHandler().dispatch(
        await entryOf(PayrollOutbox.deduction),
      );

      expect(result.outcome, OutboxDispatchOutcome.failed);
    });
  });

  group('geste du circuit', () {
    PayrollGestureOutboxHandler gestureHandler() => PayrollGestureOutboxHandler(
      api: api,
      gestures: PayrollGestureDao(db),
      payrolls: PayrollDao(db),
      outbox: outbox,
      currentUser: user,
      extras: const {},
      now: () => 5,
    );

    Future<void> submit() => PayrollGestureDao(db).add(
      const PayrollGestureRequestDto(
        gestureId: 'g-1',
        month: _month,
        kind: 'SUBMIT',
        clientRecordedAt: '2026-10-26T10:00:00Z',
        authorId: 'u-1',
      ),
      schoolId: _school,
      nowMs: 30,
    );

    test('attend les saisies du mois posées avant lui', () async {
      await saveSaisie(_saisie());
      await submit();

      final result = await gestureHandler().dispatch(
        await entryOf(PayrollOutbox.gesture),
      );

      expect(result.outcome, OutboxDispatchOutcome.blocked);
    });

    test('attend le catalogue posé avant lui', () async {
      await saveType(_type());
      await submit();

      final result = await gestureHandler().dispatch(
        await entryOf(PayrollOutbox.gesture),
      );

      expect(result.outcome, OutboxDispatchOutcome.blocked);
    });

    test('une saisie supprimée par le serveur ne le gèle pas', () async {
      when(
        () => api.submitDeduction(any(), any()),
      ).thenThrow(_http(410, PayrollDeductionCodes.tombstoned));
      when(() => api.submitGesture(any(), any())).thenAnswer(
        (_) async => PayrollDto.tryParse({
          'id': 'p',
          'month': _month,
          'status': 'SUBMITTED',
        })!,
      );
      await saveSaisie(_saisie());
      await submit();

      final saisie = await entryOf(PayrollOutbox.deduction);
      await saisieHandler().dispatch(saisie);
      await outbox.markAcked(saisie.id);

      final result = await gestureHandler().dispatch(
        await entryOf(PayrollOutbox.gesture),
      );

      expect(result.outcome, OutboxDispatchOutcome.acked);
    });
  });

  group('annulation locale', () {
    test(
      'une rubrique jamais envoyée part avec ses saisies et sa file',
      () async {
        await saveType(_type());
        await saveSaisie(_saisie());

        await types.cancelUnsent(_school, 't-1');

        expect(await types.forSchool(_school), isEmpty);
        expect(await deductions.forSchool(_school), isEmpty);
        expect(await outbox.pendingAll(), isEmpty);
      },
    );

    test(
      'retirer une rubrique emporte ses saisies à 0 synchronisées',
      () async {
        await known();
        await db.transaction(
          (txn) => PayrollDeductionDao.applyServer(
            txn,
            _month,
            [_server(0)],
            schoolId: _school,
            nowMs: 5,
          ),
        );

        await types.remove(_school, 't-1');

        expect(await deductions.forSchool(_school), isEmpty);
      },
    );

    test('effacer un refus lu retire seulement une ligne refusée', () async {
      await db.transaction(
        (txn) => PayrollDeductionDao.applyServer(
          txn,
          _month,
          [_server(500)],
          schoolId: _school,
          nowMs: 5,
        ),
      );
      final entry = (await deductions.forSchool(
        _school,
      ))[_month]!['m-1']!.single;

      await deductions.dismiss(_month, entry, schoolId: _school);

      expect(await deductions.forSchool(_school), isNotEmpty);
    });
  });
}
