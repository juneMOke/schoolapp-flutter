import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/navigation/route_exit_guard.dart';

/// Des pages poussées sans route (`Navigator.push`) au-dessus d'une route
/// gardée : la fiche d'un agent, puis son contrat, au-dessus du personnel.
void main() {
  late GoRouter router;
  late List<String> asked;

  setUp(() => asked = []);

  Widget guarded(String name, {required bool dirty, Widget? child}) =>
      RouteExitGuard(
        hasUnsavedWork: () => dirty,
        confirmExit: () async {
          asked.add(name);
          return true;
        },
        child: child ?? Text(name),
      );

  Future<void> pushPageless(
    WidgetTester tester,
    String name, {
    required bool dirty,
  }) async {
    final navigator = router.routerDelegate.navigatorKey.currentState!;
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(body: guarded(name, dirty: dirty)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pump(WidgetTester tester) async {
    router = GoRouter(
      initialLocation: '/personnel',
      routes: [
        GoRoute(path: '/accueil', builder: (_, _) => const Text('accueil')),
        GoRoute(
          path: '/personnel',
          onExit: RouteExitGuard.onExit,
          builder: (_, _) => const Text('personnel'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  }

  testWidgets('la saisie la plus haute pose LA question, pour toutes', (
    tester,
  ) async {
    await pump(tester);
    await pushPageless(tester, 'agent', dirty: true);
    await pushPageless(tester, 'contrat', dirty: true);

    router.go('/accueil');
    await tester.pumpAndSettle();

    expect(asked, ['contrat']);
    expect(find.text('accueil'), findsOneWidget);
    expect(find.text('agent'), findsNothing);
  });

  testWidgets('une saisie sous une page vierge est consultée', (tester) async {
    await pump(tester);
    await pushPageless(tester, 'agent', dirty: true);
    await pushPageless(tester, 'contrat', dirty: false);

    router.go('/accueil');
    await tester.pumpAndSettle();

    expect(asked, ['agent']);
  });

  testWidgets('sortie accordée : la page sans route se referme', (
    tester,
  ) async {
    await pump(tester);
    await pushPageless(tester, 'agent', dirty: false);

    router.go('/accueil');
    await tester.pumpAndSettle();

    expect(asked, isEmpty);
    expect(find.text('agent'), findsNothing);
    expect(find.text('accueil'), findsOneWidget);
  });

  testWidgets('la garde d’une page qui RESTE n’est pas consultée', (
    tester,
  ) async {
    router = GoRouter(
      initialLocation: '/saisie',
      routes: [
        GoRoute(
          path: '/saisie',
          onExit: RouteExitGuard.onExit,
          builder: (_, _) => guarded('dessous', dirty: true),
        ),
        GoRoute(
          path: '/apercu',
          onExit: RouteExitGuard.onExit,
          builder: (_, _) => const Text('aperçu'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    unawaited(router.push('/apercu'));
    await tester.pumpAndSettle();

    router.pop();
    await tester.pumpAndSettle();

    expect(asked, isEmpty);
    expect(find.text('dessous'), findsOneWidget);
  });
}
