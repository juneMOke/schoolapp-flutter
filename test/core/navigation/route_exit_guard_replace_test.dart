import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/navigation/route_exit_guard.dart';

/// Une fiche neuve qui prend l'adresse de l'agent créé (`…/nouveau` →
/// `…/{id}`, `replace` sous [Router.neglect]) reste montée : la garde
/// consultée par ce `replace` doit se réarmer, sans quoi la saisie faite
/// ensuite partirait sans question au Précédent du navigateur.
void main() {
  late bool dirty;
  late int asked;

  setUp(() {
    dirty = false;
    asked = 0;
  });

  Widget probe(String label) => RouteExitGuard(
    hasUnsavedWork: () => dirty,
    confirmExit: () async {
      asked++;
      return false;
    },
    child: Scaffold(
      body: Builder(
        builder: (context) => Column(
          children: [
            Text('fiche $label'),
            TextButton(
              onPressed: () =>
                  Router.neglect(context, () => context.replace('/home/f/a')),
              child: const Text('adopter'),
            ),
          ],
        ),
      ),
    ),
  );

  Future<GoRouter> pump(WidgetTester tester, String initial) async {
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(
          path: '/home/:subMenuId',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/home/f/nouveau'),
              child: const Text('ouvrir'),
            ),
          ),
          routes: [
            GoRoute(
              path: 'nouveau',
              onExit: RouteExitGuard.onExit,
              builder: (_, _) => probe('neuve'),
            ),
            GoRoute(
              path: ':agentId',
              onExit: RouteExitGuard.onExit,
              builder: (_, state) => probe(state.pathParameters['agentId']!),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> adoptThenEditThenBack(
    WidgetTester tester,
    GoRouter router,
  ) async {
    await tester.tap(find.text('adopter'));
    await tester.pumpAndSettle();
    expect(find.text('fiche a'), findsOneWidget);

    // « Modifier », une saisie… puis Précédent du navigateur.
    dirty = true;
    router.go('/home/f');
    await tester.pumpAndSettle();

    expect(asked, 1, reason: 'la garde doit encore poser la question');
    expect(find.text('fiche a'), findsOneWidget);
  }

  testWidgets('fiche poussée puis adoptée : la garde protège encore', (
    tester,
  ) async {
    final router = await pump(tester, '/home/f');
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    await adoptThenEditThenBack(tester, router);
  });

  testWidgets('fiche rouverte par F5 puis adoptée : la garde protège encore', (
    tester,
  ) async {
    final router = await pump(tester, '/home/f/nouveau');
    await adoptThenEditThenBack(tester, router);
  });

  testWidgets('sortie accordée : la page partie ne garde rien', (tester) async {
    final router = await pump(tester, '/home/f/a');
    router.go('/home/f');
    await tester.pumpAndSettle();
    expect(find.text('ouvrir'), findsOneWidget);
    expect(asked, 0);
  });
}
