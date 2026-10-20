import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_split_selection.dart';

void main() {
  const intent = FacturationDetailIntent(
    studentId: 'eleve-1',
    academicYearId: 'annee-1',
    firstName: 'Grâce',
    lastName: 'Tshala',
    surname: '',
    levelName: '6e',
    levelGroupName: 'Primaire',
  );

  Future<GoRouter> pump(WidgetTester tester, {String? initial}) async {
    final router = GoRouter(
      initialLocation: initial ?? '/home/facturations',
      routes: [
        GoRoute(path: '/home/:ecran', builder: (_, _) => const Text('x')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  String location(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  testWidgets('choisir un élève l\'inscrit dans l\'adresse, le refermer l\'en '
      'retire', (tester) async {
    final router = await pump(tester);
    final selection = FacturationSplitSelection(router);
    addTearDown(selection.dispose);
    selection.select(intent);
    await tester.pumpAndSettle();
    expect(location(router), '/home/facturations?eleve=eleve-1&annee=annee-1');
    // L'identité choisie dans la liste est gardée.
    expect(selection.selected, intent);
    selection.clear();
    await tester.pumpAndSettle();
    expect(location(router), '/home/facturations');
    expect(selection.selected, isNull);
  });

  testWidgets('une adresse rechargée rouvre la fiche, par ses identifiants', (
    tester,
  ) async {
    final router = await pump(
      tester,
      initial: '/home/facturations?eleve=eleve-2&annee=annee-1',
    );
    final selection = FacturationSplitSelection(router);
    addTearDown(selection.dispose);
    expect(selection.selected?.studentId, 'eleve-2');
    expect(selection.selected?.hasStudentIdentity, isFalse);
  });

  testWidgets('Précédent (l\'adresse change) : la fiche suit', (tester) async {
    final router = await pump(tester);
    final selection = FacturationSplitSelection(router);
    addTearDown(selection.dispose);
    selection.select(intent);
    await tester.pumpAndSettle();
    router.go('/home/facturations?eleve=eleve-3&annee=annee-1');
    await tester.pumpAndSettle();
    expect(selection.selected?.studentId, 'eleve-3');
  });

  test('sans routeur, la sélection reste en mémoire', () {
    final selection = FacturationSplitSelection(null)..select(intent);
    expect(selection.selected, intent);
    selection.dispose();
  });
}
