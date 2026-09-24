import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_register_snapshot.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_queue_sort.dart';
import 'package:school_app_flutter/features/expense/presentation/projections/expense_queue_view.dart';

/// Ce que la file montre : ce qui attend, ce qui traîne, ce qui reste à payer.
void main() {
  // Samedi 12 septembre 2026.
  final today = DateTime(2026, 9, 12, 16);

  final rate = ExchangeRate(
    base: 'USD',
    quote: 'CDF',
    rateMicros: 2800 * ExchangeRate.scale,
    effectiveFrom: DateTime.utc(2026, 9, 1),
  );

  const type = ExpenseType(
    id: 'elec',
    code: 'ELEC',
    label: 'Électricité',
    shortLabel: 'Élec',
    icon: 'power',
    colorHex: '#D9A24E',
    softColorHex: '#FBF3E3',
    defaultCurrency: 'CDF',
    sortOrder: 0,
    active: true,
  );

  Expense expense(
    String id, {
    ExpenseStatus status = ExpenseStatus.pending,
    String day = '2026-09-10',
    int cents = 1000,
    int reminders = 0,
    DateTime? decidedAt,
    DateTime? deletedAt,
  }) => Expense(
    id: id,
    typeId: 'elec',
    title: 'Dépense $id',
    amountInCents: cents,
    currency: 'USD',
    status: status,
    expenseDate: DateTime.parse(day),
    reminderCount: reminders,
    decidedAt: decidedAt,
    deletedAt: deletedAt,
    clientUpdatedAt: DateTime.utc(2026),
  );

  ExpenseQueueView viewOf(
    List<Expense> expenses, {
    ExpenseQueueSort sort = ExpenseQueueSort.age,
  }) => ExpenseQueueView.compute(
    snapshot: ExpenseRegisterSnapshot(
      types: const [type],
      expenses: expenses,
      usdToCdf: rate,
    ),
    sort: sort,
    today: today,
  );

  test('la file ne retient QUE ce qui attend', () {
    final view = viewOf([
      expense('attente'),
      expense('accordee', status: ExpenseStatus.approved),
      expense('payee', status: ExpenseStatus.paid),
      expense('refusee', status: ExpenseStatus.refused),
      expense('retiree', status: ExpenseStatus.retracted),
    ]);

    expect([for (final e in view.pending) e.id], ['attente']);
  });

  test('une demande RETIRÉE du registre ne fait pas la queue', () {
    final view = viewOf([
      expense('vivante'),
      expense('supprimee', deletedAt: DateTime.utc(2026, 9, 11)),
    ]);

    expect([for (final e in view.pending) e.id], ['vivante']);
  });

  test('la file IGNORE la période : une demande du mois dernier attend '
      'toujours', () {
    // C'est le point de la file : masquer les plus vieilles cacherait
    // exactement le retard qu'elle existe pour montrer.
    final view = viewOf([
      expense('vieille', day: '2026-07-04'),
      expense('recente', day: '2026-09-11'),
    ]);

    expect(view.pending, hasLength(2));
    expect(view.pending.first.id, 'vieille');
  });

  test('le total de ce qui attend est compté à part des engagements', () {
    final view = viewOf([
      expense('a', cents: 2500),
      expense('b', cents: 1500),
      expense('accordee', status: ExpenseStatus.approved, cents: 9900),
    ]);

    expect(view.pendingTotal.count, 2);
    expect(view.pendingTotal.usdCents, 4000);
    expect(view.approvedTotal.usdCents, 9900);
  });

  test('les compteurs de retard et de relance', () {
    final view = viewOf([
      expense('vieille', day: '2026-09-01'),
      expense('limite', day: '2026-09-07'),
      expense('fraiche', day: '2026-09-11', reminders: 3),
    ]);

    expect(view.overdue, 2);
    expect(view.reminded, 1);
    expect(view.oldestWaitDays, 11);
  });

  test('la plus longue attente ne dépend PAS du tri courant', () {
    // Le compteur mesure la file, pas la ligne qui se trouve en tête — un
    // tri par montant ne doit pas faire mentir « la plus ancienne ».
    final rows = [
      expense('vieille', day: '2026-09-01', cents: 100),
      expense('grosse', day: '2026-09-11', cents: 100000),
    ];

    expect(viewOf(rows).oldestWaitDays, 11);
    expect(viewOf(rows, sort: ExpenseQueueSort.amount).oldestWaitDays, 11);
  });

  test('les accordées se lisent de la décision la PLUS ANCIENNE', () {
    final view = viewOf([
      expense(
        'hier',
        status: ExpenseStatus.approved,
        decidedAt: DateTime.utc(2026, 9, 11),
      ),
      expense(
        'lundi',
        status: ExpenseStatus.approved,
        decidedAt: DateTime.utc(2026, 9, 7),
      ),
    ]);

    expect([for (final e in view.approved) e.id], ['lundi', 'hier']);
  });

  test('une accordée SANS date de décision ferme la marche, elle ne prétend '
      'pas à l\'ancienneté', () {
    // Cas courant tant que le pull ne rapporte pas les colonnes de décision.
    final view = viewOf([
      expense('inconnue', status: ExpenseStatus.approved),
      expense(
        'datee',
        status: ExpenseStatus.approved,
        decidedAt: DateTime.utc(2026, 9, 11),
      ),
    ]);

    expect([for (final e in view.approved) e.id], ['datee', 'inconnue']);
  });

  test('une file vide ne compte rien, et le dit', () {
    final view = viewOf([expense('payee', status: ExpenseStatus.paid)]);

    expect(view.isEmpty, isTrue);
    expect(view.overdue, 0);
    expect(view.reminded, 0);
    expect(view.oldestWaitDays, 0);
  });
}
