import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/network_status_cubit.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';
import 'package:school_app_flutter/features/recouvrement/domain/repositories/fee_control_export_repository.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_selection_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/fee_control_results_section.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/exports/fee_control_export.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockFeeControlBloc extends MockBloc<FeeControlEvent, FeeControlState>
    implements FeeControlBloc {}

class _MockExportRepository extends Mock
    implements FeeControlExportRepository {}

class _MockConnectivity extends Mock implements ConnectivityService {}

class _StubTitlesCubit extends Cubit<FeeSectionTitlesState>
    implements FeeSectionTitlesCubit {
  _StubTitlesCubit() : super(const FeeSectionTitlesState());

  @override
  Future<void> load() async {}
}

const _row = FeeControlRow(
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
  line: LocalRecoveryLine(
    schoolLevelId: 'l1',
    studentId: 's1',
    charges: [
      RecoveryChargePosition(
        feeCode: 'TUITION',
        position: FeeChargePosition(
          currency: 'USD',
          expectedInCents: 150000,
          paidMirrorInCents: 50000,
          paidPendingInCents: 0,
        ),
      ),
    ],
  ),
);

/// « A payé au moins… » sur un champ vide : le bloc a résolu le plancher à 0
/// dans la devise des lignes lues (R3).
const _atLeastZero = FeeControlQuery(
  academicYearId: 'ay-1',
  classroomId: 'cls-1',
  feeCodes: ['TUITION'],
  statusFilter: FeeControlPaymentFilter.threshold,
  threshold: Money(0, 'USD'),
  page: 0,
  size: 10,
);

FeeControlState _state(EnrollmentLoadStatus status) => FeeControlState(
  status: status,
  rows: const [_row],
  totalElements: 1,
  totalPages: 1,
  studentsInScope: 1,
  breakdown: const FeeControlBreakdown(partial: 1),
  currencies: const {'USD'},
  lastQuery: _atLeastZero,
);

/// Les exports du résultat (R11) : ni pendant un rechargement (I4), ni hors
/// ligne (Q2, M9) ; sous « a payé au moins… », toujours avec un seuil (B3).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockFeeControlBloc bloc;
  late _MockExportRepository repository;

  setUpAll(() {
    registerFallbackValue(FeeControlExportFilter.all);
    registerFallbackValue(RecoveryExportFormat.pdf);
  });

  setUp(() {
    bloc = _MockFeeControlBloc();
    repository = _MockExportRepository();
    when(() => bloc.results).thenReturn(const [_row]);
    when(
      () => repository.export(
        classroomId: any(named: 'classroomId'),
        feeCodes: any(named: 'feeCodes'),
        filter: any(named: 'filter'),
        threshold: any(named: 'threshold'),
        lines: any(named: 'lines'),
        format: any(named: 'format'),
      ),
    ).thenAnswer((_) async => const Left(NetworkFailure()));
    GetIt.instance.registerSingleton<FeeControlExportRepository>(repository);
  });

  tearDown(() => GetIt.instance.reset());

  void goOffline() {
    final connectivity = _MockConnectivity();
    when(connectivity.isOnline).thenAnswer((_) async => false);
    when(
      () => connectivity.onStatusChange,
    ).thenAnswer((_) => const Stream.empty());
    GetIt.instance.registerFactory<NetworkStatusCubit>(
      () => NetworkStatusCubit(connectivity),
    );
  }

  Future<void> pump(WidgetTester tester, FeeControlState state) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    when(() => bloc.state).thenReturn(state);
    whenListen(
      bloc,
      const Stream<FeeControlState>.empty(),
      initialState: state,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<FeeControlBloc>.value(value: bloc),
            BlocProvider<FeeControlSelectionCubit>(
              create: (_) => FeeControlSelectionCubit(),
            ),
            BlocProvider<FeeSectionTitlesCubit>(
              create: (_) => _StubTitlesCubit(),
            ),
          ],
          child: AppPageBackground(
            child: FeeControlResultsSection(
              state: state,
              onViewRequested: (_) {},
              onRowTapped: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  OutlinedButton button(WidgetTester tester, String label) =>
      tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.byWidgetPredicate((w) => w is OutlinedButton),
        ),
      );

  testWidgets('I4 — pendant un rechargement, PDF et Excel sont inactifs : '
      'les lignes en mémoire sont celles de l\'ancienne question', (
    tester,
  ) async {
    await pump(tester, _state(EnrollmentLoadStatus.loading));

    expect(button(tester, 'PDF').onPressed, isNull);
    expect(button(tester, 'Excel').onPressed, isNull);
  });

  testWidgets('sur un résultat servi et en ligne, les exports sont actifs', (
    tester,
  ) async {
    await pump(tester, _state(EnrollmentLoadStatus.success));

    expect(button(tester, 'PDF').onPressed, isNotNull);
    expect(button(tester, 'Excel').onPressed, isNotNull);
  });

  testWidgets('M9 — hors ligne, les exports attendent le réseau et le disent', (
    tester,
  ) async {
    goOffline();
    await pump(tester, _state(EnrollmentLoadStatus.success));

    expect(button(tester, 'PDF').onPressed, isNull);
    expect(button(tester, 'Excel').onPressed, isNull);
    expect(
      find.byWidgetPredicate(
        (w) => w is Tooltip && w.message == 'Les exports attendent le réseau.',
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('I4 — garde : rien ne part tant que l\'état n\'est pas servi', (
    tester,
  ) async {
    await pump(tester, _state(EnrollmentLoadStatus.loading));

    final context = tester.element(find.byType(FeeControlResultsSection));
    await openFeeControlExport(context, RecoveryExportFormat.pdf);
    await tester.pump();

    verifyNever(
      () => repository.export(
        classroomId: any(named: 'classroomId'),
        feeCodes: any(named: 'feeCodes'),
        filter: any(named: 'filter'),
        threshold: any(named: 'threshold'),
        lines: any(named: 'lines'),
        format: any(named: 'format'),
      ),
    );
  });

  testWidgets('B3 — champ vide sous « a payé au moins… » : l\'export part '
      'avec un seuil de 0 et sa devise', (tester) async {
    await pump(tester, _state(EnrollmentLoadStatus.success));

    await tester.tap(find.text('PDF'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final captured = verify(
      () => repository.export(
        classroomId: 'cls-1',
        feeCodes: const ['TUITION'],
        filter: FeeControlExportFilter.paidAtLeast,
        threshold: captureAny(named: 'threshold'),
        lines: any(named: 'lines'),
        format: RecoveryExportFormat.pdf,
      ),
    ).captured;
    expect(captured.single, const Money(0, 'USD'));
  });
}
