import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/eteelo_overflow_text.dart';

void main() {
  Future<void> pump(WidgetTester tester, double width) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: const EteeloOverflowText('MUKENDI ILUNGA Grâce-Divine'),
          ),
        ),
      ),
    ),
  );

  testWidgets('tronqué : le texte entier au survol', (tester) async {
    await pump(tester, 40);
    expect(find.byType(Tooltip), findsOneWidget);
    expect(
      tester.widget<Tooltip>(find.byType(Tooltip)).message,
      'MUKENDI ILUNGA Grâce-Divine',
    );
  });

  testWidgets('entier : pas d’info-bulle qui le doublerait', (tester) async {
    await pump(tester, 800);
    expect(find.byType(Tooltip), findsNothing);
  });
}
