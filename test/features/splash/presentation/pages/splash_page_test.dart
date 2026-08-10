import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/splash/presentation/pages/splash_page.dart';
import 'package:school_app_flutter/features/splash/presentation/widgets/eteelo_animated_symbol.dart';
import 'package:school_app_flutter/features/splash/presentation/widgets/splash_error_view.dart';
import 'package:school_app_flutter/features/splash/presentation/widgets/splash_progress_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../../test_helpers/widget_test_utils.dart';

class _MockAcademicYearContextBloc
    extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

void main() {
  setUp(installCommonTestPluginMocks);
  tearDown(removeCommonTestPluginMocks);

  const loadingState = AcademicYearContextState.initial();
  const failureState = AcademicYearContextState(
    status: AcademicYearContextLoadStatus.failure,
    context: null,
    errorMessage: 'boom',
  );

  Future<_MockAcademicYearContextBloc> pumpSplash(
    WidgetTester tester, {
    required Size size,
    AcademicYearContextState state = loadingState,
  }) async {
    final bloc = _MockAcademicYearContextBloc();
    when(() => bloc.state).thenReturn(state);
    whenListen(
      bloc,
      Stream<AcademicYearContextState>.value(state),
      initialState: state,
    );

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AcademicYearContextBloc>.value(
          value: bloc,
          child: const SplashPage(),
        ),
      ),
    );
    // Avance l'animation d'entrée sans attendre la stabilisation (l'arc en
    // rotation et la barre indéterminée ne se stabilisent jamais).
    await tester.pump(const Duration(milliseconds: 900));
    return bloc;
  }

  testWidgets(
    'rend le symbole, le wordmark et la progression sur fond sombre',
    (tester) async {
      await pumpSplash(tester, size: const Size(390, 844));

      expect(find.byType(EteeloAnimatedSymbol), findsOneWidget);
      expect(find.text('ETEELO'), findsOneWidget);
      expect(find.text('CONNECT'), findsOneWidget);
      expect(find.byType(SplashProgressBar), findsOneWidget);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.surfaceDark);
    },
  );

  testWidgets('affiche la signature et la version au pied sur écran normal', (
    tester,
  ) async {
    await pumpSplash(tester, size: const Size(390, 844));
    expect(find.text('Simplifier la gestion de votre école'), findsOneWidget);
    expect(find.text('v1.0.0 (build 1)'), findsOneWidget);
  });

  testWidgets('masque le pied sous 360 dp de hauteur', (tester) async {
    await pumpSplash(tester, size: const Size(844, 320));
    expect(find.text('Simplifier la gestion de votre école'), findsNothing);
    expect(find.text('v1.0.0 (build 1)'), findsNothing);
  });

  testWidgets('échec du bootstrap → ErrorView + Réessayer relance l\'amorçage', (
    tester,
  ) async {
    final bloc = await pumpSplash(
      tester,
      size: const Size(800, 900),
      state: failureState,
    );

    // L'ErrorView remplace le chargement et s'affiche réellement (taille > 0).
    expect(find.byType(SplashErrorView), findsOneWidget);
    expect(find.byType(SplashProgressBar), findsNothing);
    expect(find.text('Connexion impossible'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);

    final cardSize = tester.getSize(find.byType(SplashErrorView));
    expect(cardSize.width, greaterThan(0));
    expect(cardSize.height, greaterThan(0));

    await tester.tap(find.text('Réessayer'));
    await tester.pump();

    verify(() => bloc.add(const AcademicYearContextRetryRequested())).called(1);
  });

  // ADR-014 §4 — un compte authentifié peut se voir refuser l'amorçage faute de
  // permission. Rien à réessayer : seul un changement de droits côté serveur y
  // remédie, et proposer « Réessayer » ne ferait que faire tourner l'agent en
  // rond sur une réponse qui ne changera pas.
  testWidgets('403 sur l\'amorçage → message de droits, sans « Réessayer »', (
    tester,
  ) async {
    await pumpSplash(
      tester,
      size: const Size(800, 900),
      state: const AcademicYearContextState(
        status: AcademicYearContextLoadStatus.failure,
        context: null,
        errorMessage: 'Access forbidden',
        insufficientPermissions: true,
      ),
    );

    expect(find.byType(SplashErrorView), findsOneWidget);
    expect(find.text('Accès non autorisé'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
    expect(find.text('Connexion impossible'), findsNothing);
  });
}
