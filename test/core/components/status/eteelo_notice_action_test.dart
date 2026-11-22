import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';

Future<void> _pump(WidgetTester tester, double width) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: EteeloNotice.warning(
              '1 élément à vérifier',
              action: TextButton(onPressed: () {}, child: const Text('Revoir')),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('large : le geste au bout de la ligne', (tester) async {
    await _pump(tester, 800);
    final text = tester.getCenter(find.text('1 élément à vérifier'));
    final action = tester.getCenter(find.text('Revoir'));
    expect((text.dy - action.dy).abs(), lessThan(1));
    expect(action.dx, greaterThan(text.dx));
  });

  testWidgets('étroit : le geste sous le texte', (tester) async {
    await _pump(tester, 328);
    final text = tester.getRect(find.text('1 élément à vérifier'));
    final action = tester.getRect(find.text('Revoir'));
    expect(action.top, greaterThan(text.bottom));
  });
}
