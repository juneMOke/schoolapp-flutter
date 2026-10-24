import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/navigation/location_params_sync.dart';

void main() {
  Future<GoRouter> pump(WidgetTester tester, {String? initial}) async {
    final router = GoRouter(
      initialLocation: initial ?? '/home/fichier',
      routes: [
        GoRoute(path: '/home/:ecran', builder: (_, _) => const _Screen()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  String location(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  testWidgets('un filtre changé s\'inscrit ; les défauts laissent l\'adresse '
      'nue', (tester) async {
    final router = await pump(tester);
    await tester.tap(find.text('enseignants'));
    await tester.pumpAndSettle();
    expect(location(router), '/home/fichier?categorie=teacher');
    await tester.tap(find.text('anciens'));
    await tester.pumpAndSettle();
    expect(location(router), '/home/fichier?categorie=teacher&tri=oldest');
    await tester.tap(find.text('défaut'));
    await tester.pumpAndSettle();
    expect(location(router), '/home/fichier');
  });

  testWidgets('une adresse rechargée rouvre les filtres', (tester) async {
    await pump(tester, initial: '/home/fichier?tri=oldest&categorie=support');
    expect(shown, {'categorie': 'support', 'tri': 'oldest'});
  });

  testWidgets('Précédent : les filtres suivent, jusqu\'aux défauts', (
    tester,
  ) async {
    final router = await pump(tester);
    router.go('/home/fichier?categorie=teacher');
    await tester.pumpAndSettle();
    expect(shown, {'categorie': 'teacher', 'tri': null});
    router.go('/home/fichier');
    await tester.pumpAndSettle();
    expect(shown, {'categorie': null, 'tri': null});
  });

  testWidgets('le reste de la requête n\'est pas touché', (tester) async {
    final router = await pump(tester, initial: '/home/fichier?onglet=paie');
    await tester.tap(find.text('enseignants'));
    await tester.pumpAndSettle();
    expect(location(router), '/home/fichier?onglet=paie&categorie=teacher');
  });
}

Map<String, String?> shown = const {};

class _Screen extends StatefulWidget {
  const _Screen();

  @override
  State<_Screen> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> {
  Map<String, String?> _filters = const {'categorie': null, 'tri': null};

  void _set(Map<String, String?> filters) => setState(() => _filters = filters);

  @override
  Widget build(BuildContext context) {
    shown = _filters;
    return LocationParamsSync(
      current: _filters,
      onLocation: _set,
      child: Column(
        children: [
          TextButton(
            onPressed: () => _set({..._filters, 'categorie': 'teacher'}),
            child: const Text('enseignants'),
          ),
          TextButton(
            onPressed: () => _set({..._filters, 'tri': 'oldest'}),
            child: const Text('anciens'),
          ),
          TextButton(
            onPressed: () => _set(const {'categorie': null, 'tri': null}),
            child: const Text('défaut'),
          ),
        ],
      ),
    );
  }
}
