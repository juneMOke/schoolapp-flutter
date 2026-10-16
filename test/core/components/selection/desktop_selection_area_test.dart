import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/selection/desktop_selection_area.dart';

void main() {
  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: DesktopSelectionArea(child: Text('ETL-RC-2526-000214')),
      ),
    ),
  );

  testWidgets('tablette : le texte reste tel quel', (tester) async {
    await pump(tester);
    expect(find.byType(SelectionArea), findsNothing);
  });

  for (final platform in [TargetPlatform.linux, TargetPlatform.windows]) {
    testWidgets('poste ${platform.name} : le texte se sélectionne', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      await pump(tester);
      expect(find.byType(SelectionArea), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('imbriquées : une seule zone de sélection', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await tester.pumpWidget(
      const MaterialApp(
        home: DesktopSelectionArea(
          child: DesktopSelectionArea(child: Text('ETL-RC-2526-000214')),
        ),
      ),
    );
    expect(find.byType(SelectionArea), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Tab passe la zone et va droit au premier champ', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final field = FocusNode();
    addTearDown(field.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DesktopSelectionArea(child: TextField(focusNode: field)),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(field.hasFocus, isTrue);
    debugDefaultTargetPlatformOverride = null;
  });
}
