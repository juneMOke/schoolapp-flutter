import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_statement.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_diploma.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';

import '../../staff/staff_builders.dart';

/// L'état de paie : groupes dans l'ordre du fichier, A/S et Crédit séparés,
/// grade ou repli sur le premier diplôme.
void main() {
  PayrollLine line(String id, {List<PayrollLineAdvance> advances = const []}) =>
      PayrollLine(
        month: '2026-10',
        staffMemberId: id,
        currency: 'USD',
        baseInCents: 30000,
        grossInCents: 30000,
        netInCents: 30000,
        advances: advances,
      );

  PayrollSnapshot snapshotOf(List<StaffMember> members) => PayrollSnapshot(
    members: members,
    contractsByMember: const {},
    settings: PayrollSettings.defaults,
    profiles: const {},
    headers: const {},
    variables: const {},
    frozenLines: const {},
    summaries: const {},
    gestures: const [],
    advances: const [],
    disbursements: const [],
    schoolYears: const [],
    shareTraces: const {},
    hasEverSynced: true,
  );

  test('un groupe par catégorie, dans l ordre du fichier, puis par nom', () {
    final groups = PayrollStatement.of(
      snapshotOf([
        member('t-2', lastName: 'Zola'),
        member('a-1', category: StaffCategory.administrative),
        member('t-1', lastName: 'Asani'),
      ]),
      [line('t-2'), line('a-1'), line('t-1')],
    );

    expect(
      [for (final g in groups) g.category],
      [
        for (final c in StaffCategory.values)
          if (c == StaffCategory.teacher || c == StaffCategory.administrative)
            c,
      ],
    );
    final teachers = groups.firstWhere(
      (g) => g.category == StaffCategory.teacher,
    );
    expect(
      [for (final r in teachers.rows) r.line.staffMemberId],
      ['t-1', 't-2'],
    );
  });

  test('A/S = échéance unique, Crédit = étalé', () {
    PayrollLineAdvance taken(String id, int installments, int cents) =>
        PayrollLineAdvance(
          advanceId: id,
          rank: 1,
          installments: installments,
          dueInCents: cents,
          takenInCents: cents,
          carriedInCents: 0,
        );
    final row = PayrollStatement.of(snapshotOf([member('m-1')]), [
      line('m-1', advances: [taken('a', 1, 4000), taken('p', 3, 2500)]),
    ]).single.rows.single;

    expect(row.salaryAdvanceInCents, 4000);
    expect(row.loanInCents, 2500);
  });

  test('grade de la fiche, sinon le niveau du premier diplôme', () {
    const withGrade = StaffMember(
      id: 'g',
      lastName: 'A',
      firstName: 'B',
      category: StaffCategory.teacher,
      syncState: RecordSyncState.synced,
      grade: 'A1',
    );
    const withDiploma = StaffMember(
      id: 'd',
      lastName: 'A',
      firstName: 'B',
      category: StaffCategory.teacher,
      syncState: RecordSyncState.synced,
      diplomas: [StaffDiploma(level: 'L2 — Licence', title: 'Pédagogie')],
    );

    expect(PayrollStatement.gradeOf(withGrade), 'A1');
    expect(PayrollStatement.gradeOf(withDiploma), 'L2');
    expect(PayrollStatement.gradeOf(null), isNull);
  });
}
