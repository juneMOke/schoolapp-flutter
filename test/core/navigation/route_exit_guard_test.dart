import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/navigation/route_exit_guard.dart';

/// Précédent du navigateur ne contourne plus une page de saisie.
///
/// Sur le web, Précédent change l'adresse : GoRouter remplace les pages sans
/// consulter `PopScope`. `router.go` simule exactement ce chemin.
void main() {
  late GoRouter router;
  late bool busy;
  late bool dirty;
  late int asked;
  late bool answer;

  setUp(() {
    busy = false;
    dirty = false;
    asked = 0;
    answer = false;
  });

  late ValueNotifier<int> refresh;

  Future<void> pump(WidgetTester tester) async {
    refresh = ValueNotifier<int>(0);
    addTearDown(refresh.dispose);
    router = GoRouter(
      initialLocation: '/',
      refreshListenable: refresh,
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('liste')),
        GoRoute(
          path: '/saisie',
          onExit: RouteExitGuard.onExit,
          builder: (_, _) => RouteExitGuard(
            isBusy: () => busy,
            hasUnsavedWork: () => dirty,
            confirmExit: () async {
              asked++;
              return answer;
            },
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  RouteExitGuard.release(context);
                  context.pop();
                },
                child: const Text('enregistré'),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    unawaited(router.push('/saisie'));
    await tester.pumpAndSettle();
  }

  Future<void> back(WidgetTester tester) async {
    router.go('/');
    await tester.pumpAndSettle();
  }

  bool onForm() => find.text('enregistré').evaluate().isNotEmpty;

  testWidgets('rien de saisi : on part librement', (tester) async {
    await pump(tester);
    await back(tester);
    expect(onForm(), isFalse);
    expect(asked, 0);
  });

  testWidgets('une saisie : on demande, et « rester » garde la page', (
    tester,
  ) async {
    dirty = true;
    await pump(tester);
    await back(tester);
    expect(asked, 1);
    expect(onForm(), isTrue);
  });

  testWidgets('une saisie : « partir » quitte la page', (tester) async {
    dirty = true;
    answer = true;
    await pump(tester);
    await back(tester);
    expect(onForm(), isFalse);
  });

  testWidgets('une écriture en vol retient la page, sans question', (
    tester,
  ) async {
    busy = true;
    dirty = true;
    await pump(tester);
    await back(tester);
    expect(asked, 0);
    expect(onForm(), isTrue);
  });

  testWidgets('une sortie décidée par la page ne repose pas la question', (
    tester,
  ) async {
    dirty = true;
    await pump(tester);
    await tester.tap(find.text('enregistré'));
    await tester.pumpAndSettle();
    expect(asked, 0);
    expect(onForm(), isFalse);
  });

  group('rafraîchissement du routeur', () {
    // Droits relus par la synchronisation : go_router recrée la page empilée
    // et consulte `onExit` alors que personne ne part (go_router #128122).
    testWidgets('sans le signaler, la garde poserait la question', (
      tester,
    ) async {
      dirty = true;
      await pump(tester);
      refresh.value++;
      await tester.pumpAndSettle();
      expect(asked, 1);
    });

    testWidgets('signalé, il ne demande rien et garde la saisie', (
      tester,
    ) async {
      dirty = true;
      await pump(tester);
      RouteExitGuard.duringRouterRefresh(() => refresh.value++);
      await tester.pumpAndSettle();
      expect(asked, 0);
      expect(onForm(), isTrue);
    });

    testWidgets('l’image suivante, Précédent redemande', (tester) async {
      dirty = true;
      await pump(tester);
      RouteExitGuard.duringRouterRefresh(() => refresh.value++);
      await tester.pumpAndSettle();
      await back(tester);
      expect(asked, 1);
    });
  });
}
