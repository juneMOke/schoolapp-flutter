import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_refusal_panel.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ctrl+Entrée refuse depuis le motif, comme le bouton — motif exigé.
void main() {
  late List<String> refused;

  Future<void> pump(WidgetTester tester) {
    refused = [];
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ExpenseRefusalPanel(onConfirm: refused.add, onCancel: () {}),
          ),
        ),
      ),
    );
  }

  Future<void> ctrlEnter(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
  }

  testWidgets('Ctrl+Entrée refuse avec le motif saisi', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'Devis manquant');
    await ctrlEnter(tester);
    expect(refused, ['Devis manquant']);
  });

  testWidgets('sans motif, Ctrl+Entrée ne refuse rien', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await ctrlEnter(tester);
    expect(refused, isEmpty);
  });
}
