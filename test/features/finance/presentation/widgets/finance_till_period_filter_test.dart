import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/entities/stats_context.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_finance_till_usecase.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_till_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_period_filter.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockGetFinanceTillUseCase extends Mock
    implements GetFinanceTillUseCase {}

final _till = FinanceTill(
  context: StatsContext(
    schoolYear: '2025-2026',
    period: 'day',
    periodStart: DateTime.utc(2026, 5, 15),
    periodEnd: DateTime.utc(2026, 5, 15),
    generatedAt: DateTime.utc(2026, 5, 15, 18),
  ),
  timeZone: 'Africa/Kinshasa',
  byCurrency: const [],
);

/// La fenêtre que la caisse totalise.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => registerFallbackValue(TillPeriod.day));

  late _MockGetFinanceTillUseCase useCase;
  late FinanceTillBloc bloc;

  setUp(() {
    useCase = _MockGetFinanceTillUseCase();
    when(
      () => useCase(period: any(named: 'period')),
    ).thenAnswer((_) async => Right(_till));
    bloc = FinanceTillBloc(getFinanceTillUseCase: useCase);
  });

  tearDown(() => bloc.close());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<FinanceTillBloc>.value(
        value: bloc,
        child: const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: FinanceTillPeriodFilter()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('quatre grains, le jour d’abord', (tester) async {
    await pump(tester);

    // « Aujourd'hui » n'existait pas : l'ancien écran n'allait pas plus fin que
    // la semaine, faute d'unité de compte à la journée du côté du recouvrement.
    expect(find.text("Aujourd'hui"), findsOneWidget);
    expect(find.text('Cette semaine'), findsOneWidget);
    expect(find.text('Ce mois'), findsOneWidget);
    expect(find.text('Cette année'), findsOneWidget);
  });

  testWidgets('changer de grain redemande la caisse sur cette fenêtre', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('Ce mois'));
    await tester.pumpAndSettle();

    expect(bloc.state.selectedPeriod, TillPeriod.month);
    verify(() => useCase(period: TillPeriod.month)).called(1);
    // Aucune ancre n'accompagne le grain : les quatre portent toujours la
    // fenêtre courante. Le serveur refuse en 400 une ancre incohérente, et un
    // état qui garderait l'ancienne produirait un écran d'erreur sur un simple
    // clic d'onglet.
    verifyNever(() => useCase(period: TillPeriod.day));
  });
}
