import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_local.dart';
import 'package:school_app_flutter/features/payroll/data/repositories/payroll_deduction_repository_impl.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_sync_api.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction_codes.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_local_writer.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../offline_full_db.dart';

class _MockApi extends Mock implements PayrollSyncApi {}

class _Ids implements IdGenerator {
  @override
  String newId() => 'new-id';
}

const _school = 's-1';
const _type = PayrollDeductionType(id: 't-1', label: 'Cartes', sortOrder: 10);

DioException _http(int status, String code) => DioException(
  requestOptions: RequestOptions(path: '/'),
  response: Response(
    requestOptions: RequestOptions(path: '/'),
    statusCode: status,
    data: {'detailCode': code, 'detail': code},
  ),
);

void main() {
  late Database db;
  late _MockApi api;
  late PayrollLocal local;
  late PayrollDeductionRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() async {
    db = await openFullOfflineDb();
    api = _MockApi();
    local = PayrollLocal.on(db);
    repository = PayrollDeductionRepositoryImpl(
      local: local,
      writer: StaffLocalWriter(
        currentUser: CurrentUserContext()..set('u-1', schoolId: _school),
      ),
      api: api,
      extras: const {},
      ids: _Ids(),
      now: () => DateTime.utc(2026, 10, 20, 9),
    );
  });
  tearDown(() => db.close());

  Future<void> knownType() async {
    await repository.saveTypes(const [_type]);
    await db.update('payroll_deduction_types', {'server_known': 1});
    await db.delete(OutboxDao.table);
  }

  test('le libellé part sans ses espaces de bordure', () async {
    await repository.saveTypes(const [
      PayrollDeductionType(id: 't-1', label: '  Cartes ', sortOrder: 10),
    ]);

    expect(
      (await local.deductionTypes.forSchool(_school)).single.label,
      'Cartes',
    );
  });

  test(
    'variables et saisies partent ensemble, une entrée par montant',
    () async {
      await repository.saveEntries(
        '2026-10',
        variables: const PayrollVariables(
          staffMemberId: 'm-1',
          overtimeMinutes: 60,
        ),
        entries: const [
          PayrollDeductionEntry(
            staffMemberId: 'm-1',
            deductionTypeId: 't-1',
            amountInCents: 500,
            currency: 'USD',
          ),
          PayrollDeductionEntry(
            staffMemberId: 'm-1',
            deductionTypeId: 't-2',
            amountInCents: 0,
            currency: 'USD',
          ),
        ],
      );

      expect(await OutboxDao(db).pendingAll(), hasLength(3));
      expect(
        (await local.deductions.forSchool(_school))['2026-10']!['m-1'],
        hasLength(2),
      );
    },
  );

  group('suppression', () {
    test('jamais envoyée : annulée en local, sans appel', () async {
      await repository.saveTypes(const [_type]);

      final result = await repository.removeType('t-1');

      expect(result, const Right<Failure, Unit>(unit));
      verifyNever(() => api.deleteDeductionType(any(), any()));
      expect(await local.deductionTypes.forSchool(_school), isEmpty);
      expect(await OutboxDao(db).pendingAll(), isEmpty);
    });

    test('connue du serveur : retirée après son accord', () async {
      when(
        () => api.deleteDeductionType(any(), any()),
      ).thenAnswer((_) async {});
      await knownType();

      await repository.removeType('t-1');

      expect(await local.deductionTypes.forSchool(_school), isEmpty);
    });

    test('déjà saisie : le refus se nomme, la rubrique reste', () async {
      when(
        () => api.deleteDeductionType(any(), any()),
      ).thenThrow(_http(422, PayrollDeductionCodes.inUse));
      await knownType();

      final result = await repository.removeType('t-1');

      expect(
        result.fold((f) => (f as PayrollRuleFailure).rule, (_) => null),
        PayrollRule.deductionTypeInUse,
      );
      expect(await local.deductionTypes.forSchool(_school), hasLength(1));
    });

    test('hors ligne : refus réseau, la rubrique reste', () async {
      when(() => api.deleteDeductionType(any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionError,
        ),
      );
      await knownType();

      final result = await repository.removeType('t-1');

      expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
      expect(await local.deductionTypes.forSchool(_school), hasLength(1));
    });

    test('déjà supprimée au serveur : retirée ici aussi', () async {
      when(
        () => api.deleteDeductionType(any(), any()),
      ).thenThrow(_http(410, PayrollDeductionCodes.tombstoned));
      await knownType();

      expect(await repository.removeType('t-1'), isA<Right<Failure, Unit>>());
      expect(await local.deductionTypes.forSchool(_school), isEmpty);
    });
  });
}
