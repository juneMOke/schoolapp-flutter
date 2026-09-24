import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_queue_sort.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_wait.dart';

/// L'attente et les trois lectures de la file, en logique pure.
void main() {
  // Samedi 12 septembre 2026.
  final today = DateTime(2026, 9, 12, 16);

  final rate = ExchangeRate(
    base: 'USD',
    quote: 'CDF',
    rateMicros: 2800 * ExchangeRate.scale,
    effectiveFrom: DateTime.utc(2026, 9, 1),
  );

  Expense expense(
    String id, {
    String day = '2026-09-10',
    int cents = 1000,
    String currency = 'USD',
    String? requester,
    int reminders = 0,
  }) => Expense(
    id: id,
    typeId: 'elec',
    title: 'Dépense $id',
    amountInCents: cents,
    currency: currency,
    status: ExpenseStatus.pending,
    expenseDate: DateTime.parse(day),
    recordedByName: requester,
    reminderCount: reminders,
    clientUpdatedAt: DateTime.utc(2026),
  );

  List<String> idsOf(List<Expense> rows) => [for (final r in rows) r.id];

  group('ExpenseWait', () {
    test('le jour même : zéro, pas « depuis 0 jour »', () {
      expect(
        ExpenseWait.daysWaiting(expense('a', day: '2026-09-12'), today: today),
        0,
      );
    });

    test('les jours se comptent en calendaire', () {
      expect(
        ExpenseWait.daysWaiting(expense('a', day: '2026-09-07'), today: today),
        5,
      );
    });

    test('une date à venir n\'attend pas « moins un jour »', () {
      expect(
        ExpenseWait.daysWaiting(expense('a', day: '2026-09-20'), today: today),
        0,
      );
    });

    test('le retard commence à 5 jours, pas à 4', () {
      expect(
        ExpenseWait.isOverdue(expense('a', day: '2026-09-08'), today: today),
        isFalse,
      );
      expect(
        ExpenseWait.isOverdue(expense('b', day: '2026-09-07'), today: today),
        isTrue,
      );
    });

    test('le seuil tiède est bien en deçà du seuil chaud', () {
      // Les deux paliers existent pour être distincts : les confondre
      // rendrait l'ocre inutile.
      expect(ExpenseWait.warmDays, lessThan(ExpenseWait.hotDays));
    });

    test('relancée : le compteur, pas une devinette sur le fil', () {
      expect(ExpenseWait.wasReminded(expense('a')), isFalse);
      expect(ExpenseWait.wasReminded(expense('b', reminders: 2)), isTrue);
    });
  });

  group('tri', () {
    test('ancienneté : la plus vieille en tête', () {
      final rows = ExpenseQueueOrder.apply(
        [
          expense('recente', day: '2026-09-11'),
          expense('vieille', day: '2026-09-02'),
          expense('moyenne', day: '2026-09-08'),
        ],
        ExpenseQueueSort.age,
        ExpenseUsdReader(rate),
      );

      expect(idsOf(rows), ['vieille', 'moyenne', 'recente']);
    });

    test('montant : la lecture en dollars départage les devises', () {
      // 100 000 FC ≈ 35,71 $ : plus que 20 $, moins que 50 $. Comparer les
      // centimes bruts aurait mis les francs en tête à tous les coups.
      final rows = ExpenseQueueOrder.apply(
        [
          expense('vingt', cents: 2000),
          expense('francs', cents: 10000000, currency: 'CDF'),
          expense('cinquante', cents: 5000),
        ],
        ExpenseQueueSort.amount,
        ExpenseUsdReader(rate),
      );

      expect(idsOf(rows), ['cinquante', 'francs', 'vingt']);
    });

    test('montant SANS taux : les francs ferment la marche, ils ne valent '
        'pas un dollar par défaut', () {
      final rows = ExpenseQueueOrder.apply(
        [
          expense(
            'francs',
            cents: 10000000,
            currency: 'CDF',
            day: '2026-09-01',
          ),
          expense('dollars', cents: 2000, day: '2026-09-11'),
        ],
        ExpenseQueueSort.amount,
        ExpenseUsdReader.withoutRate,
      );

      expect(idsOf(rows), ['dollars', 'francs']);
    });

    test('demandeur : accents et casse ignorés', () {
      final rows = ExpenseQueueOrder.apply(
        [
          expense('z', requester: 'Zacharie'),
          expense('e', requester: 'Élodie'),
          expense('a', requester: 'alain'),
        ],
        ExpenseQueueSort.requester,
        ExpenseUsdReader(rate),
      );

      // « Élodie » se range avec « Elodie », pas après « Zacharie ».
      expect(idsOf(rows), ['a', 'e', 'z']);
    });

    test('demandeur inconnu : en fin de file, jamais en tête', () {
      final rows = ExpenseQueueOrder.apply(
        [expense('sans'), expense('avec', requester: 'Zacharie')],
        ExpenseQueueSort.requester,
        ExpenseUsdReader(rate),
      );

      expect(idsOf(rows), ['avec', 'sans']);
    });

    test('chaque tri est STABLE : deux ex æquo gardent le même ordre d\'une '
        'relecture à l\'autre', () {
      // La file se relit à chaque battement de synchro ; un tri instable y
      // ferait danser les lignes sous la main du décideur.
      for (final sort in ExpenseQueueSort.values) {
        final rows = [
          expense('b', day: '2026-09-05', requester: 'Même', cents: 1000),
          expense('a', day: '2026-09-05', requester: 'Même', cents: 1000),
          expense('c', day: '2026-09-05', requester: 'Même', cents: 1000),
        ];
        final once = idsOf(
          ExpenseQueueOrder.apply(rows, sort, ExpenseUsdReader(rate)),
        );
        final twice = idsOf(
          ExpenseQueueOrder.apply(
            rows.reversed.toList(),
            sort,
            ExpenseUsdReader(rate),
          ),
        );
        expect(once, twice, reason: sort.name);
        expect(once, ['a', 'b', 'c'], reason: sort.name);
      }
    });

    test('le tri ne modifie jamais la liste qu\'on lui donne', () {
      final rows = [expense('b', day: '2026-09-11'), expense('a')];

      ExpenseQueueOrder.apply(
        rows,
        ExpenseQueueSort.age,
        ExpenseUsdReader(rate),
      );

      expect(idsOf(rows), ['b', 'a']);
    });
  });
}
