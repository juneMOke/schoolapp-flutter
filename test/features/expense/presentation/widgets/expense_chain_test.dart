import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_chain.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_situation_note.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La chaîne et l'encart de situation : la fiche dit où en est la demande, et
/// ce qu'elle attend.
///
/// ⚠️ Aucun `AuthBloc` n'est monté ici : `PermissionGate` est alors
/// **transparent** par convention, donc l'encart d'attente montre la phrase du
/// décideur. C'est le comportement voulu des harnais qui montent un widget
/// métier seul — pas un droit accordé par défaut en production.
void main() {
  final decidedOn = DateTime.utc(2026, 9, 10, 9);

  Expense expense({
    ExpenseStatus status = ExpenseStatus.pending,
    String? decidedByName,
    DateTime? decidedAt,
    String? reason,
    DateTime? paidOn,
  }) => Expense(
    id: 'e-1',
    typeId: 't-elec',
    title: 'Facture SNEL',
    amountInCents: 38500000,
    currency: 'CDF',
    status: status,
    expenseDate: DateTime(2026, 9, 3),
    recordedByName: 'Moke Junior',
    decidedByName: decidedByName,
    decidedAt: decidedAt,
    decisionReason: reason,
    paidOn: paidOn,
    clientUpdatedAt: DateTime.utc(2026, 9, 3),
  );

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Scaffold(body: child),
    ),
  );

  group('chaîne de validation', () {
    testWidgets('en attente : le dépôt est franchi, les deux autres non', (
      tester,
    ) async {
      await pump(tester, ExpenseChain(expense: expense()));

      expect(find.text('Demandée'), findsOneWidget);
      expect(find.text('Approuvée'), findsOneWidget);
      expect(find.text('Payée'), findsOneWidget);
      // Décision et paiement restent ouverts : deux sous-lignes « en attente ».
      expect(find.text('en attente'), findsNWidgets(2));
      expect(find.textContaining('Moke Junior'), findsOneWidget);
    });

    testWidgets('accordée : le jalon de décision nomme son décideur', (
      tester,
    ) async {
      await pump(
        tester,
        ExpenseChain(
          expense: expense(
            status: ExpenseStatus.approved,
            decidedByName: 'Mbala Thérèse',
            decidedAt: decidedOn,
          ),
        ),
      );

      expect(find.textContaining('Mbala Thérèse'), findsOneWidget);
      // Seul le paiement reste ouvert.
      expect(find.text('en attente'), findsOneWidget);
    });

    testWidgets('payée : plus rien n\'attend', (tester) async {
      await pump(
        tester,
        ExpenseChain(
          expense: expense(
            status: ExpenseStatus.paid,
            decidedByName: 'Mbala Thérèse',
            decidedAt: decidedOn,
            paidOn: DateTime(2026, 9, 12),
          ),
        ),
      );

      expect(find.text('en attente'), findsNothing);
      expect(find.text('ne sera pas payée'), findsNothing);
    });

    testWidgets('un jalon franchi SANS date ne dit pas « en attente »', (
      tester,
    ) async {
      // Le cas courant tant que le pull ne rapporte pas les colonnes de
      // décision : la demande est payée, mais le poste ignore qui a accordé
      // et quand. Se contredire dans la même cellule serait pire que se taire.
      await pump(
        tester,
        ExpenseChain(
          expense: expense(
            status: ExpenseStatus.paid,
            paidOn: DateTime(2026, 9, 12),
          ),
        ),
      );

      expect(find.text('en attente'), findsNothing);
    });

    testWidgets('refusée : le refus PREND la place de l\'approbation, et le '
        'paiement est dit hors d\'atteinte', (tester) async {
      await pump(
        tester,
        ExpenseChain(
          expense: expense(
            status: ExpenseStatus.refused,
            decidedByName: 'Mbala Thérèse',
            decidedAt: decidedOn,
            reason: 'Devis non joint',
          ),
        ),
      );

      // Pas de quatrième colonne : la chaîne garde trois jalons.
      expect(find.text('Approuvée'), findsNothing);
      expect(find.text('Refusée'), findsOneWidget);
      // « en attente » promettrait une suite qui ne viendra pas.
      expect(find.text('ne sera pas payée'), findsOneWidget);
      expect(find.text('en attente'), findsNothing);
    });

    testWidgets('retirée : même anatomie, un autre mot', (tester) async {
      await pump(
        tester,
        ExpenseChain(expense: expense(status: ExpenseStatus.retracted)),
      );

      expect(find.text('Retirée'), findsOneWidget);
      expect(find.text('ne sera pas payée'), findsOneWidget);
      // Retirée sans décision : le jalon reste ouvert, sans être adverse.
      expect(find.text('en attente'), findsOneWidget);
    });
  });

  group('encart de situation', () {
    testWidgets('en attente : la phrase du décideur', (tester) async {
      await pump(tester, ExpenseSituationNote(expense: expense()));

      expect(
        find.text('À vous de décider : approuver ou refuser avec motif.'),
        findsOneWidget,
      );
    });

    testWidgets('refusée : le motif est repris sous la chaîne', (tester) async {
      await pump(
        tester,
        ExpenseSituationNote(
          expense: expense(
            status: ExpenseStatus.refused,
            decidedByName: 'Mbala Thérèse',
            reason: 'Devis non joint',
          ),
        ),
      );

      expect(find.text('Motif du refus — Mbala Thérèse'), findsOneWidget);
      expect(find.text('Devis non joint'), findsOneWidget);
    });

    testWidgets('refusée SANS motif : aucun encart plutôt qu\'un titre vide', (
      tester,
    ) async {
      await pump(
        tester,
        ExpenseSituationNote(expense: expense(status: ExpenseStatus.refused)),
      );

      expect(find.textContaining('Motif du refus'), findsNothing);
    });

    testWidgets('un état calme ne crie pas', (tester) async {
      // Ligne de contrôle d'abord : l'instrument doit VOIR un encart quand il
      // y en a un, sinon « rien trouvé » ne prouverait rien.
      await pump(tester, ExpenseSituationNote(expense: expense()));
      expect(find.byType(Text), findsWidgets);

      for (final status in [
        ExpenseStatus.approved,
        ExpenseStatus.paid,
        ExpenseStatus.retracted,
      ]) {
        await pump(
          tester,
          ExpenseSituationNote(expense: expense(status: status)),
        );

        expect(find.byType(Text), findsNothing, reason: status.name);
      }
    });
  });
}
