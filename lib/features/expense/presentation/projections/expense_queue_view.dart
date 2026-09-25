import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_register_snapshot.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_queue_sort.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_wait.dart';

/// Ce que la file de validation affiche (spec §05), calculé en une passe.
///
/// ⚠️ **Elle ignore la période** des deux autres écrans, et c'est délibéré :
/// une demande déposée le mois dernier attend toujours. La compter sur la
/// fenêtre courante ferait disparaître les plus vieilles — exactement celles
/// que la file existe pour montrer.
class ExpenseQueueView extends Equatable {
  /// Les demandes en attente de décision, dans l'ordre du tri courant.
  final List<Expense> pending;

  /// Les demandes accordées qui restent à payer, de la décision la plus
  /// ancienne à la plus récente.
  final List<Expense> approved;

  /// Le total de ce qui attend — **hors des totaux du tableau de bord** :
  /// rien n'est engagé tant que rien n'est décidé.
  final ExpenseTotals pendingTotal;

  final ExpenseTotals approvedTotal;

  /// Demandes qui attendent depuis [ExpenseWait.hotDays] jours ou plus.
  final int overdue;

  /// Demandes que leur demandeur a relancées au moins une fois.
  final int reminded;

  /// Jours d'attente de la plus ancienne ; `0` quand la file est vide.
  final int oldestWaitDays;

  const ExpenseQueueView({
    required this.pending,
    required this.approved,
    required this.pendingTotal,
    required this.approvedTotal,
    required this.overdue,
    required this.reminded,
    required this.oldestWaitDays,
  });

  static const ExpenseQueueView empty = ExpenseQueueView(
    pending: [],
    approved: [],
    pendingTotal: ExpenseTotals.zero,
    approvedTotal: ExpenseTotals.zero,
    overdue: 0,
    reminded: 0,
    oldestWaitDays: 0,
  );

  factory ExpenseQueueView.compute({
    required ExpenseRegisterSnapshot snapshot,
    required ExpenseQueueSort sort,
    required DateTime today,
  }) {
    final reader = snapshot.usdReader;
    final pending = <Expense>[];
    final approved = <Expense>[];
    for (final expense in snapshot.expenses) {
      // Un retrait quitte le registre : il ne fait pas la queue non plus.
      if (expense.isWithdrawn) continue;
      switch (expense.status) {
        case ExpenseStatus.pending:
          pending.add(expense);
        case ExpenseStatus.approved:
          approved.add(expense);
        case ExpenseStatus.paid:
        case ExpenseStatus.refused:
        case ExpenseStatus.retracted:
          break;
      }
    }
    // Les accordées se lisent dans l'ordre où elles ont été décidées : la
    // plus vieille dette de l'école en tête. Sans date de décision — cas
    // courant tant que le pull ne la rapporte pas — la ligne ferme la marche
    // plutôt que de prétendre à l'ancienneté.
    approved.sort((a, b) {
      final left = a.decidedAt;
      final right = b.decidedAt;
      if (left == null || right == null) {
        if ((left == null) != (right == null)) return left == null ? 1 : -1;
        return a.id.compareTo(b.id);
      }
      final byDate = left.compareTo(right);
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });
    var overdue = 0;
    var reminded = 0;
    for (final expense in pending) {
      if (ExpenseWait.isOverdue(expense, today: today)) overdue++;
      if (ExpenseWait.wasReminded(expense)) reminded++;
    }
    final ordered = ExpenseQueueOrder.apply(pending, sort, reader);
    return ExpenseQueueView(
      pending: ordered,
      approved: approved,
      pendingTotal: ExpenseTotals.of(ordered, reader),
      approvedTotal: ExpenseTotals.of(approved, reader),
      overdue: overdue,
      reminded: reminded,
      // Toujours l'attente la plus longue, quel que soit le tri courant : le
      // compteur mesure la file, pas la ligne qui se trouve en tête.
      oldestWaitDays: pending.fold(0, (longest, expense) {
        final days = ExpenseWait.daysWaiting(expense, today: today);
        return days > longest ? days : longest;
      }),
    );
  }

  bool get isEmpty => pending.isEmpty;

  @override
  List<Object?> get props => [
    pending,
    approved,
    pendingTotal,
    approvedTotal,
    overdue,
    reminded,
    oldestWaitDays,
  ];
}
