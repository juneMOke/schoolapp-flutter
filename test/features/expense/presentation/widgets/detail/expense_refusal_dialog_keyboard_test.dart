import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_reason_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ctrl+Entrée refuse depuis le motif, comme le bouton — motif exigé.
void main() {
  late List<String?> refused;

  final expense = Expense(
    id: 'e-1',
    number: 'DEP-0412',
    typeId: 't-elec',
    title: 'Facture SNEL',
    amountInCents: 38500000,
    currency: 'CDF',
    status: ExpenseStatus.pending,
    expenseDate: DateTime(2026, 9, 3),
    clientUpdatedAt: DateTime.utc(2026, 9, 3),
  );

  Future<void> pump(WidgetTester tester) async {
    refused = [];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => refused.add(
                await showExpenseRefusalDialog(context, expense: expense),
              ),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  Future<void> ctrlEnter(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
  }

  testWidgets('Ctrl+Entrée refuse avec le motif saisi', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'Devis manquant');
    await ctrlEnter(tester);
    expect(refused, ['Devis manquant']);
  });

  testWidgets('sans motif, Ctrl+Entrée ne refuse rien', (tester) async {
    await pump(tester);
    await ctrlEnter(tester);
    expect(refused, isEmpty);
    expect(find.byType(ExpenseReasonDialog), findsOneWidget);
  });
}
