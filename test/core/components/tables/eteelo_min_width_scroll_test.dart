import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_min_width_scroll.dart';

const _table = Key('table');

void main() {
  Future<void> pump(WidgetTester tester, double width) => tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: SizedBox(
          width: width,
          child: const EteeloMinWidthScroll(
            minWidth: 600,
            child: Row(
              key: _table,
              children: [
                Expanded(child: Text('colonne')),
                Expanded(child: Text('colonne')),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('assez large : pleine largeur, sans défilement', (tester) async {
    await pump(tester, 800);
    expect(tester.getSize(find.byKey(_table)).width, 800);
    expect(find.byType(SingleChildScrollView), findsNothing);
  });

  testWidgets('trop étroit : garde sa largeur et défile', (tester) async {
    await pump(tester, 400);
    expect(tester.getSize(find.byKey(_table)).width, 600);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
