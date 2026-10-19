import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/layout/master_detail_layout.dart';

void main() {
  Future<void> pump(WidgetTester tester, VoidCallback? onClose) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MasterDetailLayout(
              master: const TextField(),
              detail: const Text('fiche'),
              onCloseDetail: onClose,
            ),
          ),
        ),
      );

  testWidgets('Échap referme la fiche ouverte', (tester) async {
    var closed = 0;
    await pump(tester, () => closed++);
    await tester.tap(find.byType(TextField));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(closed, 1);
  });

  testWidgets('rien d\'ouvert : Échap ne fait rien', (tester) async {
    await pump(tester, null);
    await tester.tap(find.byType(TextField));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(find.text('fiche'), findsOneWidget);
  });
}
