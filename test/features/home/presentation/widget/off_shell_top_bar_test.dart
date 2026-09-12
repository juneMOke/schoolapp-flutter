import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/features/home/presentation/widget/off_shell_top_bar.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

const _bar = OffShellTopBar(
  eyebrow: 'Finances',
  title: 'Facturations',
  backTooltip: 'Retour',
  shellSubMenuId: 'facturations',
);

const _offShell = '/hors-coquille';

Future<GoRouter> _pump(
  WidgetTester tester, {
  required String initialLocation,
}) async {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/origine',
        builder: (context, state) => const Scaffold(body: Text('origine')),
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
      GoRoute(
        path: _offShell,
        builder: (context, state) =>
            const Scaffold(appBar: _bar, body: SizedBox()),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return router;
}

/// Une page de sous-menu poussée par sa route sort de la coquille : sans cette
/// barre, elle s'affichait sans rien pour dire où l'on est, ni pour revenir.
void main() {
  testWidgets('la barre nomme le module, puis l\'écran', (tester) async {
    await _pump(tester, initialLocation: _offShell);

    expect(find.text('FINANCES'), findsOneWidget);
    expect(find.text('Facturations'), findsOneWidget);
  });

  testWidgets('poussée, sa flèche DÉPILE vers l\'écran d\'où l\'on vient', (
    tester,
  ) async {
    final router = await _pump(tester, initialLocation: '/origine');
    unawaited(router.push(_offShell));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();

    expect(find.text('origine'), findsOneWidget);
  });

  testWidgets('sans rien à dépiler — un lien profond —, elle rejoint son '
      'sous-menu DANS la coquille', (tester) async {
    await _pump(tester, initialLocation: _offShell);

    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();

    expect(find.text('coquille:facturations'), findsOneWidget);
  });
}
