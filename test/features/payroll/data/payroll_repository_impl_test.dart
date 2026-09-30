import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_local.dart';
import 'package:school_app_flutter/features/payroll/data/repositories/payroll_repository_impl.dart';
import 'package:school_app_flutter/features/payroll/data/repositories/payroll_snapshot_reader.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_dto.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_drafts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_advance_rules.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_contract_dao.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_local_writer.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_contract_dto.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_repository.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../offline_full_db.dart';
import '../../staff/staff_builders.dart';
import '../../staff/staff_fixtures.dart';

class _MockStaff extends Mock implements StaffRepository {}

class _Ids implements IdGenerator {
  int _n = 0;
  @override
  String newId() => 'id-${++_n}';
}

void main() {
  late Database db;
  late PayrollRepositoryImpl repository;
  late PayrollLocal local;

  setUp(() async {
    db = await openFullOfflineDb();
    local = PayrollLocal.on(db);
    final staff = _MockStaff();
    when(staff.loadFile).thenAnswer(
      (_) async => Right(
        StaffFileSnapshot(
          members: [member('m-1')],
          documentsByMember: const {},
          documentTypes: const [],
          hasEverSynced: true,
        ),
      ),
    );
    await StaffContractDao(db).applyPulled(
      [StaffContractDeltaDto.tryParse(staffContractJson('c-1'))!],
      schoolId: 's-1',
      nowMs: 1,
    );
    repository = PayrollRepositoryImpl(
      reader: PayrollSnapshotReader(
        staff: staff,
        contracts: StaffContractDao(db),
        local: local,
      ),
      local: local,
      writer: StaffLocalWriter(
        currentUser: CurrentUserContext()..set('u-1', schoolId: 's-1'),
      ),
      ids: _Ids(),
      now: () => DateTime.utc(2026, 10, 12, 9),
    );
  });
  tearDown(() => db.close());

  Future<PayrollSnapshot> load() async =>
      (await repository.load()).getOrElse(() => throw StateError('load'));

  test('une ligne figée retrouve le début de son contrat', () async {
    await local.payrolls.apply(
      [
        PayrollDto.tryParse({
          'id': 'p-9',
          'month': '2026-09',
          'status': 'VALIDATED',
          'validationGestureId': 'g-v',
          'lines': [
            {
              'staffMemberId': 'm-1',
              'contractId': 'c-1',
              'currency': 'USD',
              'grossInCents': 32000,
              'netInCents': 32000,
            },
          ],
        })!,
      ],
      schoolId: 's-1',
      nowMs: 1,
    );

    final line = (await load()).frozenLines['2026-09']!.single;

    expect(line.contractFrom, '2025-09-01');
  });

  test(
    'une avance part dans la devise du contrat, au mois de départ',
    () async {
      final snapshot = await load();
      final firstMonth = PayrollAdvanceRules.defaultFirstMonth(
        snapshot,
        '2026-10-12',
      );
      const reason = SalaryAdvanceReason.medical;
      final draft = SalaryAdvanceDraft(
        staffMemberId: 'm-1',
        amount: const Money(6000, 'USD'),
        installments: 3,
        firstMonth: firstMonth,
        reason: reason,
        mode: PayoutMode.cash,
        grantedOn: '2026-10-12',
      );
      expect(PayrollAdvanceRules.refusalOf(snapshot, draft), isNull);

      await repository.grantAdvance(draft);

      final advance = (await load()).advances.single;
      expect(advance.firstMonth, '2026-10');
      expect(advance.amount, const Money(6000, 'USD'));
      final entry = (await OutboxDao(db).pendingAll()).single;
      expect(entry.aggregateId, 'payroll:2026-10');
      expect(entry.payload, contains('"authorId":"u-1"'));
    },
  );

  test('une avance en francs pour un contrat en dollars est refusée', () async {
    final snapshot = await load();

    expect(
      PayrollAdvanceRules.refusalOf(
        snapshot,
        const SalaryAdvanceDraft(
          staffMemberId: 'm-1',
          amount: Money(600000, 'CDF'),
          installments: 1,
          firstMonth: '2026-10',
          reason: SalaryAdvanceReason.rent,
          mode: PayoutMode.cash,
          grantedOn: '2026-10-12',
        ),
      ),
      isNotNull,
    );
  });
}
