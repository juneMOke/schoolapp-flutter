import 'package:bloc_test/bloc_test.dart';
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

/// Pour les assertions de **rendu**, un bloc figé à un état donné.
///
/// Le vrai bloc répond dans une micro-tâche que `pumpAndSettle` n'attend pas de
/// façon fiable : l'état arrive, mais la frame qui le rend peut tomber après la
/// fin du test. Les gestes restent éprouvés sur le vrai bloc, ci-dessus ; ce
/// stub ne sert qu'à demander « avec CET état, qu'affiche le filtre ? ».
class _StubTillBloc extends MockBloc<FinanceTillEvent, FinanceTillState>
    implements FinanceTillBloc {}

final _till = FinanceTill(
  context: StatsContext(
    schoolYear: '2025-2026',
    period: 'day',
    periodStart: DateTime.utc(2026, 5, 15),
    periodEnd: DateTime.utc(2026, 5, 15),
    generatedAt: DateTime.utc(2026, 5, 15, 18),
  ),
  timeZone: 'Africa/Kinshasa',
  encaisse: const [],
  impute: const [],
);

/// La fenêtre que la caisse totalise.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => registerFallbackValue(const TillWindow.day()));

  late _MockGetFinanceTillUseCase useCase;
  late FinanceTillBloc bloc;

  setUp(() {
    useCase = _MockGetFinanceTillUseCase();
    when(
      () => useCase(window: any(named: 'window')),
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

  testWidgets('quatre segments, le jour d’abord — et pas « Cette année »', (
    tester,
  ) async {
    await pump(tester);

    // « Aujourd'hui » n'existait pas sur l'ancien écran, qui n'allait pas plus
    // fin que la semaine faute d'unité de compte à la journée.
    expect(find.text("Aujourd'hui"), findsOneWidget);
    expect(find.text('Cette semaine'), findsOneWidget);
    expect(find.text('Ce mois'), findsOneWidget);
    expect(find.text('Période'), findsOneWidget);
    // Le contrat sert `year` et le modèle sait le construire ; la spec ne l'a
    // jamais dessiné, et le porteur a tranché pour la spec.
    expect(find.text('Cette année'), findsNothing);
  });

  testWidgets('changer de grain redemande la caisse sur cette fenêtre', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('Ce mois'));
    await tester.pumpAndSettle();

    expect(bloc.state.selectedWindow, const TillWindow.month());
    verify(() => useCase(window: const TillWindow.month())).called(1);
    // Aucune borne n'accompagne un grain déductible : le serveur refuse en 400
    // un `from`/`to` posé sur autre chose que `custom`.
    expect(bloc.state.selectedWindow.apiFrom, isNull);
    expect(bloc.state.selectedWindow.apiTo, isNull);
  });

  group('la période libre', () {
    Future<void> pumpWindow(WidgetTester tester, TillWindow window) async {
      final stub = _StubTillBloc();
      final state = FinanceTillState(selectedWindow: window);
      when(() => stub.state).thenReturn(state);
      whenListen(
        stub,
        const Stream<FinanceTillState>.empty(),
        initialState: state,
      );
      addTearDown(stub.close);

      await tester.pumpWidget(
        BlocProvider<FinanceTillBloc>.value(
          value: stub,
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

    testWidgets('les deux champs n’apparaissent QUE sur « Période »', (
      tester,
    ) async {
      await pumpWindow(tester, const TillWindow.day());
      expect(find.textContaining('Du ·'), findsNothing);
      expect(find.textContaining('Au ·'), findsNothing);

      await pumpWindow(
        tester,
        TillWindow.custom(
          from: DateTime(2026, 8, 10),
          to: DateTime(2026, 9, 9),
        ),
      );
      expect(find.textContaining('Du ·'), findsOneWidget);
      expect(find.textContaining('Au ·'), findsOneWidget);
    });

    testWidgets('les bornes affichées sont celles de la fenêtre', (
      tester,
    ) async {
      await pumpWindow(
        tester,
        TillWindow.custom(
          from: DateTime(2026, 8, 10),
          to: DateTime(2026, 9, 9),
        ),
      );

      expect(find.textContaining('10/08/2026'), findsOneWidget);
      expect(find.textContaining('09/09/2026'), findsOneWidget);
    });

    testWidgets('le clic sur « Période » demande une plage par défaut', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Période'));
      await tester.pumpAndSettle();

      final window = bloc.state.selectedWindow;
      expect(window.isCustom, isTrue);
      expect(
        window.dayCount,
        31,
        reason:
            'J-30 → aujourd’hui, bornes incluses. Deux champs vides n’auraient '
            'rien à charger et l’écran se viderait sur un clic d’onglet',
      );
      // La requête part avec ses DEUX bornes — sans elles, le serveur répond 400.
      expect(window.apiFrom, isNotNull);
      expect(window.apiTo, isNotNull);
    });

    testWidgets('revenir sur un grain déductible retire les bornes', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Période'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cette semaine'));
      await tester.pumpAndSettle();

      expect(bloc.state.selectedWindow, const TillWindow.week());
      expect(
        bloc.state.selectedWindow.apiFrom,
        isNull,
        reason:
            'des bornes posées sur une autre période partent en 400 — le '
            'serveur refuse plutôt que d’ignorer un paramètre hors sujet',
      );
    });
  });
}
