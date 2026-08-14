import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_error_type.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_results_error_state.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/fee_control/fee_control_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/fee_control_data_table.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/fee_control_results_view.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/fee_control_search_invitation_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/states/fee_control_results_empty_state.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class MockFeeControlBloc extends MockBloc<FeeControlEvent, FeeControlState>
    implements FeeControlBloc {}

const tQuery = FeeControlQuery(
  academicYearId: 'ay-1',
  schoolLevelGroupId: 'g1',
  schoolLevelId: 'l1',
  feeCode: 'TUITION',
  statusFilter: FeeControlPaymentFilter.settled,
  firstName: '',
  lastName: '',
  surname: '',
  page: 0,
  size: 10,
);

/// Même recherche, mais bornée à une classe.
const tClassroomQuery = FeeControlQuery(
  academicYearId: 'ay-1',
  schoolLevelGroupId: 'g1',
  schoolLevelId: 'l1',
  classroomId: 'cls-1',
  feeCode: 'TUITION',
  statusFilter: FeeControlPaymentFilter.settled,
  firstName: '',
  lastName: '',
  surname: '',
  page: 0,
  size: 10,
);

const tRow = FeeControlRow(
  summary: EnrollmentSummary(
    enrollmentId: 'enr-1',
    enrollmentCode: 'code-1',
    status: 'COMPLETED',
    syncState: SyncState.synced,
    student: StudentSummary(
      id: 's1',
      firstName: 'Debbie',
      lastName: 'MOKE',
      surname: 'Junior',
      dateOfBirth: '2010-01-01',
      gender: Gender.female,
    ),
  ),
  aggregate: LocalFeeChargeAggregate(
    studentId: 's1',
    expectedInCents: 150000,
    paidMirrorInCents: 150000,
    paidPendingInCents: 0,
    currency: 'USD',
  ),
);

Future<void> _pumpView(WidgetTester tester, FeeControlState state) async {
  final bloc = MockFeeControlBloc();
  when(() => bloc.state).thenReturn(state);
  whenListen(bloc, const Stream<FeeControlState>.empty(), initialState: state);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<FeeControlBloc>.value(
        value: bloc,
        child: AppPageBackground(
          child: FeeControlResultsView(onViewRequested: (_) {}),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('aucune recherche → carte d\'invitation', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpView(tester, const FeeControlState.initial());

    expect(find.byType(FeeControlSearchInvitationCard), findsOneWidget);
  });

  testWidgets('résultats → tableau', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpView(
      tester,
      const FeeControlState(
        status: EnrollmentLoadStatus.success,
        rows: [tRow],
        totalElements: 1,
        totalPages: 1,
        studentsInScope: 1,
        breakdown: FeeControlBreakdown(settled: 1),
        lastQuery: tQuery,
      ),
    );

    expect(find.byType(FeeControlDataTable), findsOneWidget);
    expect(find.text('MOKE'), findsOneWidget);
  });

  testWidgets('classe peuplée mais sans créance de ce frais → message dédié', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpView(
      tester,
      const FeeControlState(
        status: EnrollmentLoadStatus.success,
        studentsInScope: 12,
        breakdown: FeeControlBreakdown(),
        lastQuery: tQuery,
      ),
    );

    expect(find.byType(FeeControlResultsEmptyState), findsOneWidget);
    expect(
      find.textContaining('ne porte ce frais'),
      findsOneWidget,
      reason: 'ne pas confondre grille incomplète et critère trop étroit',
    );
  });

  testWidgets('personne ne correspond au statut → message générique', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpView(
      tester,
      const FeeControlState(
        status: EnrollmentLoadStatus.success,
        studentsInScope: 12,
        breakdown: FeeControlBreakdown(settled: 12),
        lastQuery: tQuery,
      ),
    );

    expect(find.textContaining('ne porte ce frais'), findsNothing);
    expect(
      find.textContaining('Aucun élève ne correspond à ces critères'),
      findsOneWidget,
    );
    // Les puces rappellent le frais et le statut demandés, avec les libellés
    // du détail Facturation (code de frais localisé, statut de créance).
    expect(find.text('Frais : Frais de scolarité'), findsOneWidget);
    expect(find.text('Statut : Payé'), findsOneWidget);
  });

  testWidgets('classe choisie, roster local absent → invite à synchroniser', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpView(
      tester,
      const FeeControlState(
        status: EnrollmentLoadStatus.success,
        studentsInScope: 0,
        classroomRosterSize: 0,
        lastQuery: tClassroomQuery,
      ),
    );

    expect(
      find.textContaining('n\'est pas encore descendue sur cet appareil'),
      findsOneWidget,
    );
  });

  testWidgets('roster connu mais aucun dossier local → message distinct', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpView(
      tester,
      const FeeControlState(
        status: EnrollmentLoadStatus.success,
        studentsInScope: 0,
        classroomRosterSize: 24,
        lastQuery: tClassroomQuery,
      ),
    );

    expect(
      find.textContaining('n\'a de dossier d\'inscription local'),
      findsOneWidget,
    );
    expect(find.textContaining('n\'est pas encore descendue'), findsNothing);
  });

  testWidgets(
    'classe choisie et peuplée mais sans créance → message « ne porte pas ce '
    'frais », pas un message de synchro',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpView(
        tester,
        const FeeControlState(
          status: EnrollmentLoadStatus.success,
          studentsInScope: 24,
          classroomRosterSize: 24,
          breakdown: FeeControlBreakdown(),
          lastQuery: tClassroomQuery,
        ),
      );

      expect(find.textContaining('ne porte ce frais'), findsOneWidget);
    },
  );

  testWidgets('échec → écran d\'erreur partagé', (tester) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpView(
      tester,
      const FeeControlState(
        status: EnrollmentLoadStatus.failure,
        errorType: EnrollmentErrorType.server,
        errorMessage: 'base illisible',
        lastQuery: tQuery,
      ),
    );

    expect(find.byType(EnrollmentResultsErrorState), findsOneWidget);
  });
}
