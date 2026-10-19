import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_layout.dart';

void main() {
  Future<void> pump(WidgetTester tester, Size window) async {
    tester.view.physicalSize = window;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FacturationCreatePaymentLayout(
              header: [SizedBox(key: Key('origine'), height: 40)],
              payer: SizedBox(key: Key('payeur'), height: 120),
              date: SizedBox(key: Key('date'), height: 60),
              charges: SizedBox(key: Key('creances'), height: 300),
              footer: SizedBox(key: Key('motif'), height: 80),
            ),
          ),
        ),
      ),
    );
  }

  Rect rectOf(WidgetTester tester, String key) =>
      tester.getRect(find.byKey(Key(key)));

  testWidgets('tablette : une colonne, le payeur avant les créances', (
    tester,
  ) async {
    await pump(tester, const Size(1024, 1366));
    expect(
      rectOf(tester, 'payeur').top,
      lessThan(rectOf(tester, 'creances').top),
    );
    expect(
      rectOf(tester, 'date').top,
      lessThan(rectOf(tester, 'creances').top),
    );
    expect(
      rectOf(tester, 'motif').top,
      greaterThan(rectOf(tester, 'creances').top),
    );
  });

  testWidgets('grand écran : les créances à gauche, payeur et date à droite', (
    tester,
  ) async {
    await pump(tester, const Size(1440, 900));
    final charges = rectOf(tester, 'creances');
    final payer = rectOf(tester, 'payeur');
    expect(payer.left, greaterThan(charges.right));
    expect(payer.top, charges.top);
    expect(payer.width, AppDimensions.paymentSideColumnWidth);
    expect(rectOf(tester, 'date').left, payer.left);
    expect(rectOf(tester, 'motif').left, charges.left);
    // L'origine d'une correction reste au-dessus des deux colonnes.
    expect(rectOf(tester, 'origine').bottom, lessThanOrEqualTo(charges.top));
  });
}
