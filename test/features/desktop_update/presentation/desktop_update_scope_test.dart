import 'dart:async';

import 'package:dartz/dartz.dart' show Either, Right;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/navigation/route_exit_guard.dart';
import 'package:school_app_flutter/features/desktop_update/domain/entities/app_version.dart';
import 'package:school_app_flutter/features/desktop_update/domain/entities/desktop_release.dart';
import 'package:school_app_flutter/features/desktop_update/domain/repositories/desktop_update_repository.dart';
import 'package:school_app_flutter/features/desktop_update/domain/repositories/last_run_version_store.dart';
import 'package:school_app_flutter/features/desktop_update/presentation/cubit/desktop_update_cubit.dart';
import 'package:school_app_flutter/features/desktop_update/presentation/widgets/desktop_update_scope.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../fixtures.dart';

class _Repo implements DesktopUpdateRepository {
  DesktopUpdateOffer? next = offer();

  @override
  Future<Either<Failure, DesktopUpdateOffer?>> fetchOffer(
    AppVersion installed,
  ) async => Right(next);

  @override
  Future<Either<Failure, VerifiedInstaller>> download(
    DesktopRelease release, {
    void Function(int received, int total)? onProgress,
    DownloadCancellation? cancellation,
  }) => Completer<Either<Failure, VerifiedInstaller>>().future;

  @override
  Future<Either<Failure, bool>> install(VerifiedInstaller installer) async =>
      const Right(true);
}

class _Store implements LastRunVersionStore {
  @override
  Future<String?> read() async => '1.8.0';

  @override
  Future<void> write(String version) async {}
}

void main() {
  late _Repo repo;
  late GoRouter router;
  late DesktopUpdateCubit cubit;
  late int quits;

  setUp(() {
    repo = _Repo();
    quits = 0;
  });

  Future<void> pump(
    WidgetTester tester, {
    String initial = '/home',
    Size size = const Size(1440, 900),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('accueil')),
        ),
        GoRoute(
          path: '/home/:screen',
          builder: (_, state) => Scaffold(
            body: state.pathParameters['screen'] == 'facturations'
                // Une saisie en cours : la garde de sortie le dit.
                ? RouteExitGuard(
                    hasUnsavedWork: () => true,
                    confirmExit: () async => true,
                    child: const Text('saisie'),
                  )
                : Text(state.pathParameters['screen']!),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('connexion')),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: DesktopUpdateScope(
            enabled: true,
            router: router,
            onQuit: () => quits++,
            createCubit: () => cubit = DesktopUpdateCubit(
              repository: repo,
              installed: const AppVersion(1, 8, 0),
              pendingOperations: () async => 0,
              lastRun: _Store(),
              ticks: const Stream.empty(),
              exitApp: () {},
            ),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sur l’accueil : la fenêtre s’ouvre ; « Plus tard » la ferme', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('La version 1.9.0 est disponible'), findsOneWidget);
    expect(find.text('Réglages'), findsOneWidget);
    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();
    expect(find.text('La version 1.9.0 est disponible'), findsNothing);
    expect(cubit.state.hasOffer, isTrue);
  });

  testWidgets('écran de saisie sous l’accueil : rien', (tester) async {
    await pump(tester, initial: '/home/resultats-saisie');
    expect(find.text('La version 1.9.0 est disponible'), findsNothing);
  });

  testWidgets('tableau de bord : la fenêtre s’ouvre', (tester) async {
    await pump(tester, initial: '/home/finances-dashboard');
    expect(find.text('La version 1.9.0 est disponible'), findsOneWidget);
  });

  testWidgets('connexion : seulement si la mise à jour est obligatoire', (
    tester,
  ) async {
    await pump(tester, initial: '/login');
    expect(find.text('La version 1.9.0 est disponible'), findsNothing);
    repo.next = offer(minimum: const AppVersion(1, 9, 0));
    await cubit.check();
    await tester.pumpAndSettle();
    expect(find.text('Mise à jour obligatoire'), findsOneWidget);
  });

  testWidgets('pendant une saisie : rien, jusqu’au retour à l’accueil', (
    tester,
  ) async {
    await pump(tester, initial: '/home/facturations');
    expect(find.text('La version 1.9.0 est disponible'), findsNothing);
    router.go('/home');
    await tester.pumpAndSettle();
    expect(find.text('La version 1.9.0 est disponible'), findsOneWidget);
  });

  testWidgets('demandée depuis le menu : s’ouvre même hors de l’accueil', (
    tester,
  ) async {
    await pump(tester, initial: '/home/resultats-saisie');
    cubit.reopen();
    await tester.pumpAndSettle();
    expect(find.text('La version 1.9.0 est disponible'), findsOneWidget);
  });

  testWidgets(
    'obligatoire : « Quitter » au lieu de « Plus tard », Échap sans effet',
    (tester) async {
      repo.next = offer(minimum: const AppVersion(1, 9, 0));
      await pump(tester);
      expect(find.text('Mise à jour obligatoire'), findsOneWidget);
      expect(find.text('Plus tard'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Mise à jour obligatoire'), findsOneWidget);
      await tester.tap(find.text('Quitter'));
      expect(quits, 1);
    },
  );

  testWidgets('« Mettre à jour » : le téléchargement s’affiche avec Annuler', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Mettre à jour'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
  });

  for (final (name, size) in [
    ('téléphone', const Size(360, 740)),
    ('7 pouces paysage', const Size(1024, 600)),
    ('poste', const Size(1920, 1080)),
  ]) {
    testWidgets('tient au format $name, texte ×1,3', (tester) async {
      repo.next = offer(minimum: const AppVersion(1, 9, 0));
      await pump(tester, size: size, textScale: 1.3);
      expect(find.text('Mise à jour obligatoire'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
