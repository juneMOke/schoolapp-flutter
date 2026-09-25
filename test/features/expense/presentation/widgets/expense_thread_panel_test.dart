import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_message.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_thread_panel.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le fil tel que le serveur l'écrit depuis le 2026-09-25 : `DEPOSIT` et
/// `EDIT` viennent du pull, et un `EDIT` arrive au corps **vide** — le libellé
/// de l'acte suffit, le serveur ne fabrique aucun texte.
void main() {
  ExpenseMessage message({
    required String id,
    required ExpenseAct? act,
    required String body,
  }) => ExpenseMessage(
    id: id,
    expenseId: 'e-1',
    body: body,
    act: act,
    authorId: 'u-9',
    authorName: 'Moke Junior',
    createdAt: DateTime.utc(2026, 9, 12, 9),
    syncState: ExpenseSyncState.synced,
  );

  Future<void> pump(WidgetTester tester, List<ExpenseMessage> messages) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ExpenseThreadPanel(messages: messages),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Iterable<Text> emptyTexts(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .where((text) => text.data != null && text.data!.isEmpty);

  testWidgets('un EDIT au corps vide ne laisse pas de ligne blanche', (
    tester,
  ) async {
    await pump(tester, [message(id: 'm-1', act: ExpenseAct.edit, body: '')]);

    expect(find.text('Demande modifiée'), findsOneWidget);
    expect(emptyTexts(tester), isEmpty);
  });

  testWidgets('un corps non vide reste affiché sous son acte', (tester) async {
    await pump(tester, [
      message(id: 'm-1', act: ExpenseAct.deposit, body: 'Compteur bloc B'),
    ]);

    expect(find.text('Compteur bloc B'), findsOneWidget);
  });
}
