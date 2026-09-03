import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_error_type.dart';
import 'package:school_app_flutter/features/fee_control/presentation/bloc/fee_control_bloc.dart';
import 'package:school_app_flutter/features/fee_control/presentation/widgets/fee_control_summary_band.dart';
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

Future<void> _pumpBand(WidgetTester tester, FeeControlState state) async {
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
        child: const AppPageBackground(child: FeeControlSummaryBand()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('annonce les quatre compteurs et leurs parts', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpBand(
      tester,
      const FeeControlState(
        status: EnrollmentLoadStatus.success,
        studentsInScope: 25,
        breakdown: FeeControlBreakdown(settled: 12, partial: 8, none: 5),
        lastQuery: tQuery,
      ),
    );

    expect(find.byType(EteeloKpiBand), findsOneWidget);
    expect(find.text('Élèves concernés'), findsOneWidget);
    // Libellés empruntés au détail Facturation (`studentChargeStatus*`) : un
    // même état ne change pas de nom d'un écran à l'autre.
    expect(find.text('Payé'), findsOneWidget);
    expect(find.text('Partiel'), findsOneWidget);
    expect(find.text('À régler'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets(
    'les compteurs ignorent le filtre : soldés, partiels et sans paiement '
    'restent annoncés même quand le tableau n\'en montre qu\'un',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Recherche filtrée sur « Soldé » — le bandeau montre quand même les 3.
      await _pumpBand(
        tester,
        const FeeControlState(
          status: EnrollmentLoadStatus.success,
          studentsInScope: 3,
          breakdown: FeeControlBreakdown(settled: 1, partial: 1, none: 1),
          lastQuery: tQuery,
        ),
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.text('1'), findsNWidgets(3));
    },
  );

  testWidgets('absent tant qu\'aucun contrôle n\'a abouti', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpBand(tester, const FeeControlState.initial());

    expect(find.byType(EteeloKpiBand), findsNothing);
  });

  testWidgets('absent quand la classe ne porte pas ce frais', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpBand(
      tester,
      const FeeControlState(
        status: EnrollmentLoadStatus.success,
        studentsInScope: 12,
        breakdown: FeeControlBreakdown(),
        lastQuery: tQuery,
      ),
    );

    expect(find.byType(EteeloKpiBand), findsNothing);
  });

  testWidgets('absent sur un échec', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpBand(
      tester,
      const FeeControlState(
        status: EnrollmentLoadStatus.failure,
        errorType: EnrollmentErrorType.server,
        lastQuery: tQuery,
      ),
    );

    expect(find.byType(EteeloKpiBand), findsNothing);
  });
}
