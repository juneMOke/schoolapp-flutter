import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_pickers.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('tablette : la date se choisit au calendrier', () {
    expect(eteeloDateEntryMode, DatePickerEntryMode.calendar);
  });

  test('bureau : la date se tape au clavier', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    expect(eteeloDateEntryMode, DatePickerEntryMode.input);
  });

  testWidgets('bureau : le sélecteur s’ouvre sur la saisie', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showEteeloDatePicker(
              context: context,
              initialDate: DateTime(2010, 3, 12),
              firstDate: DateTime(1900),
              lastDate: DateTime(2026, 12, 31),
            ),
            child: const Text('date'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('date'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}
