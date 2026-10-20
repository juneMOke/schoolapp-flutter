import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/navigation/location_tab_sync.dart';

enum _Tab { ledger, payslips, history }

void main() {
  Future<GoRouter> pump(WidgetTester tester, {String? initial}) async {
    final router = GoRouter(
      initialLocation: initial ?? '/home/paie',
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

  String shown() => shownTab;

  testWidgets('changer d\'onglet l\'inscrit ; le premier est l\'adresse nue', (
    tester,
  ) async {
    final router = await pump(tester);
    await tester.tap(find.text('payslips'));
    await tester.pumpAndSettle();
    expect(location(router), '/home/paie?onglet=payslips');
    await tester.tap(find.text('ledger'));
    await tester.pumpAndSettle();
    expect(location(router), '/home/paie');
  });

  testWidgets('une adresse rechargée rouvre l\'onglet', (tester) async {
    await pump(tester, initial: '/home/paie?onglet=history');
    expect(shown(), 'history');
  });

  testWidgets('Précédent (l\'adresse change) : l\'onglet suit, jusqu\'au '
      'premier', (tester) async {
    final router = await pump(tester);
    router.go('/home/paie?onglet=history');
    await tester.pumpAndSettle();
    expect(shown(), 'history');
    router.go('/home/paie');
    await tester.pumpAndSettle();
    expect(shown(), 'ledger');
  });

  testWidgets('un onglet inconnu dans l\'adresse ne change rien', (
    tester,
  ) async {
    await pump(tester, initial: '/home/paie?onglet=inconnu');
    expect(shown(), 'ledger');
  });
}

String shownTab = '';

class _Screen extends StatefulWidget {
  const _Screen();

  @override
  State<_Screen> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> {
  _Tab _tab = _Tab.ledger;

  @override
  Widget build(BuildContext context) {
    shownTab = _tab.name;
    return LocationTabSync<_Tab>(
      values: _Tab.values,
      current: _tab,
      onLocationTab: (tab) => setState(() => _tab = tab),
      child: Column(
        children: [
          for (final tab in _Tab.values)
            TextButton(
              onPressed: () => setState(() => _tab = tab),
              child: Text(tab.name),
            ),
        ],
      ),
    );
  }
}
