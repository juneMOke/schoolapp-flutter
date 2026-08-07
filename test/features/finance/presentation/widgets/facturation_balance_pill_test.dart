import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_balance_pill.dart';

Future<void> _pump(WidgetTester tester, {required bool hasBalance}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: FacturationBalancePill(
            hasBalance: hasBalance,
            label: hasBalance ? '150 USD dû' : 'À jour',
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('solde dû : libellé et icône portefeuille', (tester) async {
    await _pump(tester, hasBalance: true);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('150 USD dû'), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
  });

  testWidgets('pastille « à jour » quand le solde est nul', (tester) async {
    await _pump(tester, hasBalance: false);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('À jour'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });
}
