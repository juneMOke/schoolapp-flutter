import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/labels/audience_note.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget note) =>
      tester.pumpWidget(MaterialApp(home: Scaffold(body: note)));

  testWidgets('visible par les parents : un œil', (tester) async {
    await pump(tester, const AudienceNote('Visible'));
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    expect(find.text('Visible'), findsOneWidget);
  });

  testWidgets('interne : un cadenas', (tester) async {
    await pump(tester, const AudienceNote.internal('Interne'));
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });
}
