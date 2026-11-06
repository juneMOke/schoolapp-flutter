import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction_codes.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_header.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/presentation/pages/payroll_page.dart';

import '../../../test_helpers/reference_formats.dart';
import '../../staff/staff_builders.dart';
import '../payroll_builders.dart';
import 'payroll_screen_harness.dart';

class _MockNavigationBloc extends MockBloc<NavigationEvent, NavigationState>
    implements NavigationBloc {}

const _month = '2026-10';

/// Les bandeaux du livre qui portent un geste à droite : un agent sans
/// contrat (« Ouvrir le fichier du personnel »), une retenue refusée
/// (« J'ai lu »), un versement refusé (« Annuler ce versement »). Sur un
/// téléphone en texte ×1,3, le bouton écrasait la note voisine.
PayrollSnapshot _snapshot() => PayrollSnapshot(
  members: [
    member('m-1', lastName: 'Mayala', firstName: 'Ruth'),
    member('m-2', lastName: 'Kabeya', firstName: 'Jonas'),
  ],
  contractsByMember: {
    'm-1': [contract('m-1')],
    // Son seul contrat a été refusé : l'agent est sans contrat.
    'm-2': [contract('m-2', syncState: RecordSyncState.failed)],
  },
  settings: PayrollSettings.defaults,
  profiles: const {},
  headers: {
    _month: const PayrollHeader(
      id: 'p',
      month: _month,
      status: PayrollStatus.draft,
    ),
  },
  variables: const {},
  deductionTypes: const [
    PayrollDeductionType(id: 'a', label: 'Cartes', sortOrder: 10),
  ],
  deductions: {
    _month: {
      'm-1': [
        const PayrollDeductionEntry(
          staffMemberId: 'm-1',
          deductionTypeId: 'a',
          amountInCents: 500,
          currency: 'USD',
          syncState: RecordSyncState.failed,
          syncErrorCode: PayrollDeductionCodes.tombstoned,
        ),
      ],
    },
  },
  frozenLines: const {},
  summaries: const {},
  gestures: const [],
  advances: const [],
  disbursements: const [
    PayrollDisbursement(
      id: 'd-1',
      month: '2026-09',
      staffMemberId: 'm-1',
      validationGestureId: 'g-v',
      amount: Money(25000, 'USD'),
      mode: PayoutMode.cash,
      paidAt: '2026-09-30T10:00:00.000Z',
      syncState: RecordSyncState.failed,
    ),
  ],
  schoolYears: const [(start: '2025-09-01', end: '2027-07-02')],
  shareTraces: const {},
  hasEverSynced: true,
);

void main() {
  testAtReferenceFormats('les bandeaux à geste du livre tiennent', (
    tester,
    format,
  ) async {
    final navigation = _MockNavigationBloc();
    when(() => navigation.state).thenReturn(
      const NavigationState(
        menuItems: [],
        isSidebarExpanded: true,
        currentTitle: '',
      ),
    );
    await pumpPayrollScreen(
      tester,
      snapshot: _snapshot(),
      permissions: const [Perm.hrPayRead, Perm.hrPayWrite, Perm.hrStaffRead],
      child: BlocProvider<NavigationBloc>.value(
        value: navigation,
        child: const PayrollScreen(),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in [
      'Ouvrir le fichier du personnel',
      "J'ai lu",
      'Annuler ce versement',
    ]) {
      await tester.ensureVisible(find.text(label));
      expect(find.text(label), findsOneWidget, reason: label);
    }
    // Sur un téléphone, la note garde une largeur de lecture : jamais
    // écrasée par le geste.
    if (format.size.width < AppBreakpoints.dataTableCardsMax) {
      final note = find.textContaining('1 agent sans contrat');
      await tester.ensureVisible(note);
      expect(
        tester.getSize(note).width,
        greaterThan(format.size.width / 2),
        reason: 'note sans contrat',
      );
    }
  });
}
