import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/app_bars/module_top_bar.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/exchange_rates_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/fee_control_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

class _MockFeeControlBloc extends MockBloc<FeeControlEvent, FeeControlState>
    implements FeeControlBloc {}

class _MockAcademicYearBloc
    extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _StubExchangeRatesCubit extends Cubit<ExchangeRatesState>
    implements ExchangeRatesCubit {
  _StubExchangeRatesCubit() : super(const ExchangeRatesState());

  @override
  Future<void> load() async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubFeeSectionTitlesCubit extends Cubit<FeeSectionTitlesState>
    implements FeeSectionTitlesCubit {
  _StubFeeSectionTitlesCubit() : super(const FeeSectionTitlesState());

  @override
  Future<void> load() async {}
}

/// L'écran d'où l'on vient — le tableau de bord, qui pousse le contrôle.
const _origin = '/origine';
const _originText = 'Tableau de bord d\'origine';

/// L'écran nominatif ouvert par sa ROUTE — le tableau de bord le pousse — n'a
/// ni barre latérale ni TopBar. Il s'affichait donc nu : rien ne disait où l'on
/// était, ni comment revenir. Dans la coquille, en revanche, la TopBar le titre
/// déjà : une seconde barre y ferait doublon.
void main() {
  final l10n = AppLocalizationsFr();

  late _MockFeeControlBloc bloc;
  late _MockAcademicYearBloc academicYearBloc;
  late _MockAuthBloc authBloc;

  setUpAll(() {
    registerFallbackValue(const AcademicYearContextRequested());
    registerFallbackValue(const FeeControlResetRequested());
  });

  setUp(() {
    bloc = _MockFeeControlBloc();
    academicYearBloc = _MockAcademicYearBloc();
    authBloc = _MockAuthBloc();

    whenListen(
      bloc,
      const Stream<FeeControlState>.empty(),
      initialState: const FeeControlState.initial(),
    );
    whenListen(
      academicYearBloc,
      const Stream<AcademicYearContextState>.empty(),
      initialState: AcademicYearContextState(
        status: AcademicYearContextLoadStatus.success,
        context: AcademicYearContext(
          academicYear: AcademicYear(
            id: 'ay-1',
            name: '2026-2027',
            startDate: DateTime(2026, 9, 1),
            endDate: DateTime(2027, 7, 1),
            current: true,
          ),
          schoolLevelGroups: const [],
        ),
      ),
    );
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(status: AuthStatus.authenticated),
    );

    GetIt.instance.registerFactory<FeeControlBloc>(() => bloc);
    GetIt.instance.registerFactory<ExchangeRatesCubit>(
      () => _StubExchangeRatesCubit(),
    );
    GetIt.instance.registerFactory<FeeSectionTitlesCubit>(
      () => _StubFeeSectionTitlesCubit(),
    );
  });

  tearDown(() async => GetIt.instance.reset());

  Widget withBlocs(Widget child) => MultiBlocProvider(
    providers: [
      BlocProvider<AcademicYearContextBloc>.value(value: academicYearBloc),
      BlocProvider<AuthBloc>.value(value: authBloc),
    ],
    child: child,
  );

  void wideScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<GoRouter> pumpRouted(
    WidgetTester tester, {
    required String initialLocation,
  }) async {
    wideScreen(tester);
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: _origin,
          builder: (context, state) => const Scaffold(body: Text(_originText)),
        ),
        // `AppRoutesNames.home` est un NOM de route : la flèche la vise par
        // `goNamed`, le chemin importe peu.
        GoRoute(
          path: '/coquille',
          name: AppRoutesNames.home,
          builder: (context, state) => Scaffold(
            body: Text('coquille:${state.uri.queryParameters['subMenuId']}'),
          ),
        ),
        // La même fabrique que le routeur de l'application.
        GoRoute(
          path: AppRoutesNames.recouvrementControl,
          builder: (context, state) => FeeControlPage.fromRoute(state.extra),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      withBlocs(
        MaterialApp.router(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> pushControl(WidgetTester tester, GoRouter router) async {
    unawaited(router.push(AppRoutesNames.recouvrementControl));
    await tester.pumpAndSettle();
  }

  Finder inBar(Finder finder) =>
      find.descendant(of: find.byType(ModuleTopBar), matching: finder);

  testWidgets('poussé depuis le tableau de bord, l\'écran porte la barre '
      'sombre : le module, puis l\'écran', (tester) async {
    final router = await pumpRouted(tester, initialLocation: _origin);
    await pushControl(tester, router);

    expect(
      inBar(find.text(l10n.menuRecouvrement.toUpperCase())),
      findsOneWidget,
    );
    expect(inBar(find.text(l10n.subMenuFeeControl)), findsOneWidget);
  });

  testWidgets('sa flèche DÉPILE : on retrouve le tableau de bord tel qu\'on '
      'l\'a quitté, au lieu de le recharger', (tester) async {
    final router = await pumpRouted(tester, initialLocation: _origin);
    await pushControl(tester, router);

    await tester.tap(find.byTooltip(l10n.recouvrementControlBack));
    await tester.pumpAndSettle();

    expect(find.text(_originText), findsOneWidget);
    expect(find.byType(FeeControlPage), findsNothing);
  });

  testWidgets('sans pile — un lien profond —, la flèche rejoint le tableau de '
      'bord DANS la coquille', (tester) async {
    await pumpRouted(
      tester,
      initialLocation: AppRoutesNames.recouvrementControl,
    );

    await tester.tap(find.byTooltip(l10n.recouvrementControlBack));
    await tester.pumpAndSettle();

    expect(
      find.text('coquille:${MenuConstants.recouvrementDashboardId}'),
      findsOneWidget,
    );
  });

  testWidgets('dans la coquille, aucune seconde barre : la TopBar le titre '
      'déjà', (tester) async {
    wideScreen(tester);
    await tester.pumpWidget(
      withBlocs(
        const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FeeControlPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FeeControlPage), findsOneWidget);
    expect(find.byType(ModuleTopBar), findsNothing);
  });
}
