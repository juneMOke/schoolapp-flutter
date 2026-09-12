import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/app_bars/module_top_bar.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/facturation_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

class _MockAcademicYearBloc
    extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

const _origin = '/controle';
const _originText = 'Contrôle nominatif d\'origine';

/// La Facturation poussée par sa route — le bouton « Facturer » du contrôle
/// nominatif — sort de la coquille : elle s'affichait sans barre latérale ni
/// TopBar, donc sans rien pour dire où l'on est, ni pour revenir.
void main() {
  final l10n = AppLocalizationsFr();

  late _MockAcademicYearBloc academicYearBloc;

  setUpAll(() => registerFallbackValue(const AcademicYearContextRequested()));

  setUp(() {
    academicYearBloc = _MockAcademicYearBloc();
    // Le contexte académique en chargement : la barre est posée hors du
    // `BlocBuilder`, elle doit être là AVANT que l'écran ait de quoi
    // s'afficher.
    whenListen(
      academicYearBloc,
      const Stream<AcademicYearContextState>.empty(),
      initialState: const AcademicYearContextState(
        status: AcademicYearContextLoadStatus.loading,
      ),
    );
  });

  Widget withBloc(Widget child) => BlocProvider<AcademicYearContextBloc>.value(
    value: academicYearBloc,
    child: child,
  );

  /// Le chargement anime un indicateur sans fin : `pumpAndSettle` n'en
  /// reviendrait pas. On laisse passer la transition de page, et elle seule.
  Future<void> settleRoute(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<GoRouter> pumpRouted(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: _origin,
      routes: [
        GoRoute(
          path: _origin,
          builder: (context, state) => const Scaffold(body: Text(_originText)),
        ),
        // La même construction que le routeur de l'application.
        GoRoute(
          path: AppRoutesNames.facturations,
          builder: (context, state) => const FacturationPage.fromRoute(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      withBloc(
        MaterialApp.router(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await settleRoute(tester);
    return router;
  }

  Future<void> openBilling(WidgetTester tester, GoRouter router) async {
    unawaited(router.push(AppRoutesNames.facturations));
    await settleRoute(tester);
  }

  Finder inBar(Finder finder) =>
      find.descendant(of: find.byType(ModuleTopBar), matching: finder);

  testWidgets('poussée depuis le contrôle nominatif, la Facturation porte la '
      'barre sombre : Finances, puis Facturations', (tester) async {
    final router = await pumpRouted(tester);
    await openBilling(tester, router);

    expect(inBar(find.text(l10n.menuFinances.toUpperCase())), findsOneWidget);
    expect(inBar(find.text(l10n.subMenuBilling)), findsOneWidget);
  });

  testWidgets('sa flèche dépile vers l\'écran d\'où l\'on vient', (
    tester,
  ) async {
    final router = await pumpRouted(tester);
    await openBilling(tester, router);

    await tester.tap(find.byTooltip(l10n.facturationOffShellBack));
    await settleRoute(tester);

    expect(find.text(_originText), findsOneWidget);
    expect(find.byType(FacturationPage), findsNothing);
  });

  testWidgets('dans la coquille, aucune seconde barre : la TopBar le titre '
      'déjà', (tester) async {
    await tester.pumpWidget(
      withBloc(
        const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FacturationPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(FacturationPage), findsOneWidget);
    expect(find.byType(ModuleTopBar), findsNothing);
  });
}
