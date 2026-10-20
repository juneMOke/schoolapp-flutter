import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';
import 'package:school_app_flutter/router/reflected_records_parser.dart';

/// Les fiches en lecture poussées prennent leur adresse ; l'encaissement
/// jamais, et il ne la change pas.
void main() {
  const detail = '/finances/facturations/detail/eleve-1/annee-1';

  Future<GoRouter> pump(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/home/facturations',
      routes: [
        GoRoute(path: '/home/:ecran', builder: (_, _) => const Text('liste')),
        GoRoute(
          path: '/finances/facturations',
          builder: (_, _) => const Text('liste seule'),
          routes: [
            GoRoute(
              path: 'detail/:studentId/:academicYearId',
              builder: (_, _) => const Text('fiche'),
              routes: [
                GoRoute(
                  path: 'encaissement',
                  builder: (_, _) => const Text('encaissement'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: ReflectedRecordsParser.configOf(router)),
    );
    await tester.pumpAndSettle();
    return router;
  }

  String reported(GoRouter router) =>
      router.routeInformationProvider.value.uri.path;

  test(
    'la fiche de facturation fait partie des fiches qui ont une adresse',
    () {
      expect(
        ReflectedRecordsParser.reflectedPaths,
        contains(AppRoutesNames.facturationDetail),
      );
    },
  );

  testWidgets('la fiche poussée prend son adresse ; la liste reste dessous', (
    tester,
  ) async {
    final router = await pump(tester);
    router.push(detail);
    await tester.pumpAndSettle();
    expect(reported(router), detail);
    router.pop();
    await tester.pumpAndSettle();
    expect(reported(router), '/home/facturations');
    expect(find.text('liste'), findsOneWidget);
  });

  testWidgets('l\'encaissement poussé sur la fiche garde l\'adresse de la '
      'fiche', (tester) async {
    final router = await pump(tester);
    router.push(detail);
    await tester.pumpAndSettle();
    router.push('$detail/encaissement');
    await tester.pumpAndSettle();
    expect(find.text('encaissement'), findsOneWidget);
    expect(reported(router), detail);
  });

  testWidgets('une page poussée hors de la liste garde l\'adresse de base', (
    tester,
  ) async {
    final router = await pump(tester);
    router.push('/home/autre');
    await tester.pumpAndSettle();
    expect(reported(router), '/home/facturations');
  });
}
