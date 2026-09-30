import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_disbursement_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_gesture_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_variables_dao.dart';
import 'package:school_app_flutter/features/payroll/data/repositories/payroll_disbursement_regularizer.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_cancellation_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_cancellation_outbox_handler.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_disbursement_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_fact_outbox_handlers.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_gesture_outbox_handler.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_sync_api.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_write_requests.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../offline_full_db.dart';

class _MockApi extends Mock implements PayrollSyncApi {}

const _school = 's-1';

DioException _http(int status, {Map<String, dynamic>? body}) => DioException(
  requestOptions: RequestOptions(path: '/'),
  response: Response(
    requestOptions: RequestOptions(path: '/'),
    statusCode: status,
    data: body,
  ),
);

PayrollDto _payroll(String status, {String? validation, List<Map>? lines}) =>
    PayrollDto.tryParse({
      'id': 'p-10',
      'month': '2026-10',
      'status': status,
      'validationGestureId': validation,
      'lines': ?lines,
    })!;

void main() {
  late Database db;
  late _MockApi api;
  late OutboxDao outbox;
  late PayrollGestureDao gestures;
  late PayrollDisbursementDao disbursements;
  final user = CurrentUserContext()..set('u-1', schoolId: _school);

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() async {
    db = await openFullOfflineDb();
    api = _MockApi();
    outbox = OutboxDao(db);
    gestures = PayrollGestureDao(db);
    disbursements = PayrollDisbursementDao(db);
  });
  tearDown(() => db.close());

  PayrollGestureOutboxHandler gestureHandler() => PayrollGestureOutboxHandler(
    api: api,
    gestures: gestures,
    payrolls: PayrollDao(db),
    outbox: outbox,
    currentUser: user,
    extras: const {},
    now: () => 5,
  );

  Future<OutboxEntry> entry(String id) async =>
      (await outbox.pendingAll()).firstWhere((e) => e.id == id);

  Future<void> submit({String id = 'g-1', int nowMs = 20}) => gestures.add(
    PayrollGestureRequestDto(
      gestureId: id,
      month: '2026-10',
      kind: 'SUBMIT',
      clientRecordedAt: '2026-10-26T10:00:00Z',
      authorId: 'u-1',
    ),
    schoolId: _school,
    nowMs: nowMs,
  );

  Future<void> writeVariables({int nowMs = 10}) => PayrollVariablesDao(db).save(
    PayrollVariablesRequestDto(
      month: '2026-10',
      staffMemberId: 'm-1',
      overtimeMinutes: 60,
      clientUpdatedAt: '2026-10-2${nowMs % 10}T09:00:00Z',
      authorId: 'u-1',
    ),
    schoolId: _school,
    nowMs: nowMs,
  );

  group('geste du circuit', () {
    test('attend les éléments variables du mois posés avant lui', () async {
      await writeVariables(nowMs: 10);
      await submit(nowMs: 20);

      final result = await gestureHandler().dispatch(
        await entry(PayrollGestureDao.entryId('g-1')),
      );

      expect(result.outcome, OutboxDispatchOutcome.blocked);
      verifyNever(() => api.submitGesture(any(), any()));
    });

    test('mais pas ceux posés après lui, ni ceux d un autre mois', () async {
      await submit(nowMs: 20);
      await writeVariables(nowMs: 30);
      when(
        () => api.submitGesture(any(), any()),
      ).thenAnswer((_) async => _payroll('SUBMITTED'));

      final result = await gestureHandler().dispatch(
        await entry(PayrollGestureDao.entryId('g-1')),
      );

      expect(result.outcome, OutboxDispatchOutcome.acked);
      final header = (await PayrollDao(db).headers(_school))['2026-10']!;
      expect(header.status.wire, 'SUBMITTED');
    });

    test('PAYROLL_STALE garde les chiffres du serveur', () async {
      await submit();
      when(() => api.submitGesture(any(), any())).thenThrow(
        _http(
          422,
          body: {
            'detailCode': 'PAYROLL_STALE',
            'server': {
              'lineCount': 1,
              'totals': [
                {
                  'currency': 'USD',
                  'grossInCents': 100,
                  'advanceInCents': 0,
                  'netInCents': 100,
                },
              ],
              'linesDigest': 'abc',
              'lines': [
                {
                  'staffMemberId': 'M-1',
                  'currency': 'USD',
                  'grossInCents': 100,
                  'advanceInCents': 0,
                  'netInCents': 100,
                },
              ],
            },
          },
        ),
      );

      final result = await gestureHandler().dispatch(
        await entry(PayrollGestureDao.entryId('g-1')),
      );

      expect(result.outcome, OutboxDispatchOutcome.failed);
      final gesture = (await gestures.forSchool(_school)).single;
      expect(gesture.isStale, isTrue);
      expect(gesture.serverState?.lines.single.staffMemberId, 'm-1');
    });
  });

  group('versements', () {
    PayrollDisbursementRequestDto request({String validation = 'g-v'}) =>
        PayrollDisbursementRequestDto(
          disbursement: PayrollDisbursementDto(
            id: 'd-1',
            month: '2026-10',
            staffMemberId: 'm-1',
            validationGestureId: validation,
            amountInCents: 27500,
            currency: 'USD',
            mode: 'CASH',
            signedRegister: true,
            paidAt: '2026-10-28T11:40:00Z',
          ),
          authorId: 'u-1',
        );

    PayrollDisbursementOutboxHandler handler() =>
        PayrollDisbursementOutboxHandler(
          api: api,
          dao: disbursements,
          outbox: outbox,
          currentUser: user,
          extras: const {},
        );

    test('validation pas encore arrivée : attente, sans tentative', () async {
      await disbursements.add(request(), schoolId: _school, nowMs: 10);
      when(() => api.submitDisbursement(any(), any())).thenThrow(
        _http(409, body: {'detailCode': 'PAYROLL_NOT_YET_VALIDATED'}),
      );

      final result = await handler().dispatch(
        await entry(PayrollDisbursementDao.entryId('d-1')),
      );

      expect(result.outcome, OutboxDispatchOutcome.blocked);
    });

    test(
      'refusé : jamais effacé, et repart seul si le net est inchangé',
      () async {
        await disbursements.add(request(), schoolId: _school, nowMs: 10);
        when(
          () => api.submitDisbursement(any(), any()),
        ).thenThrow(_http(422, body: {'detailCode': 'PAYROLL_REOPENED_SINCE'}));
        await handler().dispatch(
          await entry(PayrollDisbursementDao.entryId('d-1')),
        );
        await outbox.markSyncError(PayrollDisbursementDao.entryId('d-1'), 'x');
        expect(
          (await disbursements.forSchool(_school)).single.needsRegularization,
          isTrue,
        );

        await PayrollDao(db).apply(
          [
            _payroll(
              'VALIDATED',
              validation: 'g-v2',
              lines: [
                {
                  'staffMemberId': 'm-1',
                  'currency': 'USD',
                  'grossInCents': 27500,
                  'netInCents': 27500,
                },
              ],
            ),
          ],
          schoolId: _school,
          nowMs: 20,
        );
        final requeued = await PayrollDisbursementRegularizer(
          payrolls: PayrollDao(db),
          disbursements: disbursements,
          now: () => 30,
        ).run(_school, authorId: 'u-1');

        expect(requeued, 1);
        final disbursement = (await disbursements.forSchool(_school)).single;
        expect(disbursement.validationGestureId, 'g-v2');
        expect(disbursement.syncState, StaffSyncState.pending);
        final queued = await entry(PayrollDisbursementDao.entryId('d-1'));
        expect(queued.payload, contains('"validationGestureId":"g-v2"'));
      },
    );

    test('annuler un versement refusé se clôt sans rien envoyer', () async {
      await disbursements.add(request(), schoolId: _school, nowMs: 10);
      await disbursements.mark('d-1', StaffSyncState.failed, code: 'X');
      await disbursements.cancel(
        const PayrollCancellationRequestDto(
          targetKey: PayrollCancellationRequestDto.disbursementKey,
          cancellationId: 'k-1',
          targetId: 'd-1',
          reason: 'Erreur de saisie',
          authorId: 'u-1',
        ),
        month: '2026-10',
        staffMemberId: 'm-1',
        schoolId: _school,
        nowMs: 20,
      );
      await outbox.markSyncError(PayrollDisbursementDao.entryId('d-1'), 'x');

      final result =
          await PayrollCancellationOutboxHandler.disbursement(
            store: disbursements.cancellations,
            sender: api.cancelDisbursement,
            outbox: outbox,
            currentUser: user,
            extras: const {},
            nowIso: () => '2026-10-29T08:00:00.000Z',
          ).dispatch(
            await entry(PayrollDisbursementDao.cancellationEntryId('k-1')),
          );

      expect(result.outcome, OutboxDispatchOutcome.acked);
      verifyNever(() => api.cancelDisbursement(any(), any()));
      expect(
        (await disbursements.forSchool(_school)).single.isCancelled,
        isTrue,
      );
    });

    test('annuler un versement en file attend son envoi', () async {
      await disbursements.add(request(), schoolId: _school, nowMs: 10);
      await disbursements.cancel(
        const PayrollCancellationRequestDto(
          targetKey: PayrollCancellationRequestDto.disbursementKey,
          cancellationId: 'k-1',
          targetId: 'd-1',
          reason: 'Erreur',
          authorId: 'u-1',
        ),
        month: '2026-10',
        staffMemberId: 'm-1',
        schoolId: _school,
        nowMs: 20,
      );

      final result =
          await PayrollCancellationOutboxHandler.disbursement(
            store: disbursements.cancellations,
            sender: api.cancelDisbursement,
            outbox: outbox,
            currentUser: user,
            extras: const {},
          ).dispatch(
            await entry(PayrollDisbursementDao.cancellationEntryId('k-1')),
          );

      expect(result.outcome, OutboxDispatchOutcome.blocked);
    });
  });
}
