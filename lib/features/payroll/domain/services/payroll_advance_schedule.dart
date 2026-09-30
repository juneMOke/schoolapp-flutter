import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/salary_advance.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_math.dart';

/// Les retenues d'avance d'un agent pour un mois : l'échéancier cumulé,
/// plafonné au brut, le reste reporté.
///
/// Toutes les entrées sont des faits : les retenues déjà figées se lisent sur
/// les lignes des paies validées ([deduct] `priorLines`), jamais dans le
/// registre des avances (N5).
abstract final class PayrollAdvanceSchedule {
  /// [advances] : les avances de l'agent, toutes devises ; [priorLines] : ses
  /// lignes figées des mois **antérieurs** à [month].
  ///
  /// Pour chaque avance, dans l'ordre de son mois de départ :
  /// - `k` = paies validées depuis le mois de départ où l'agent a une ligne
  ///   dans la devise de l'avance, [month] compris, borné à `n` (Q4) ;
  /// - `dû` = `floor(montant × k ÷ n)` − déjà retenu (tout le reste dès
  ///   `k = n`) ;
  /// - `pris` = `min(dû, brut restant)`, `report` = `dû − pris`.
  static List<PayrollLineAdvance> deduct({
    required String month,
    required String currency,
    required int grossInCents,
    required List<SalaryAdvance> advances,
    required List<PayrollLine> priorLines,
  }) {
    final eligible =
        advances
            .where(
              (advance) =>
                  advance.isLive &&
                  advance.amount.currency == currency &&
                  advance.firstMonth.compareTo(month) <= 0,
            )
            .toList()
          ..sort(_byStart);
    var capacity = grossInCents;
    final result = <PayrollLineAdvance>[];
    for (final advance in eligible) {
      final amount = advance.amount.amountInCents;
      final taken = _alreadyTaken(advance.id, priorLines);
      if (taken >= amount) continue;
      final n = advance.installments;
      final matured =
          1 +
          priorLines
              .where(
                (line) =>
                    line.currency == currency &&
                    line.month.compareTo(advance.firstMonth) >= 0 &&
                    line.month.compareTo(month) < 0,
              )
              .length;
      final rank = matured > n ? n : matured;
      final scheduled = rank >= n
          ? amount
          : PayrollMath.floorDiv(amount * rank, n);
      final due = scheduled > taken ? scheduled - taken : 0;
      final take = due < capacity ? due : capacity;
      capacity -= take;
      result.add(
        PayrollLineAdvance(
          advanceId: advance.id,
          rank: rank,
          installments: n,
          dueInCents: due,
          takenInCents: take,
          carriedInCents: due - take,
        ),
      );
    }
    return result;
  }

  static int _alreadyTaken(String advanceId, List<PayrollLine> priorLines) {
    var sum = 0;
    for (final line in priorLines) {
      for (final deduction in line.advances) {
        if (deduction.advanceId == advanceId) sum += deduction.takenInCents;
      }
    }
    return sum;
  }

  static int _byStart(SalaryAdvance a, SalaryAdvance b) {
    final byMonth = a.firstMonth.compareTo(b.firstMonth);
    if (byMonth != 0) return byMonth;
    final byGrant = a.grantedOn.compareTo(b.grantedOn);
    return byGrant != 0 ? byGrant : a.id.compareTo(b.id);
  }
}
