import 'package:school_app_flutter/features/payroll/domain/entities/payroll_advance_state.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/salary_advance.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_math.dart';

/// Les avances d'un mois : leur état ([statesOf], que le serveur tient dans
/// `AdvanceStates`), puis les retenues ([deduct], le même calcul que
/// `PayrollEngine.takes`).
abstract final class PayrollAdvanceSchedule {
  /// L'état de chaque avance vivante commencée au plus tard en [month], par
  /// agent. Tout vient des faits : les retenues se lisent sur les lignes
  /// figées des paies validées ([priorLines], mois antérieurs), jamais dans le
  /// registre (N5). Un mois sans paie, ou sans ligne dans la devise, ne fait
  /// rien mûrir (Q4).
  static Map<String, List<PayrollAdvanceState>> statesOf(
    List<SalaryAdvance> advances,
    String month,
    List<PayrollLine> priorLines,
  ) {
    final result = <String, List<PayrollAdvanceState>>{};
    for (final advance in advances) {
      if (!advance.isLive || advance.firstMonth.compareTo(month) > 0) continue;
      final currency = advance.amount.currency;
      var matured = 0;
      var taken = 0;
      for (final line in priorLines) {
        if (line.staffMemberId != advance.staffMemberId ||
            line.month.compareTo(month) >= 0) {
          continue;
        }
        if (line.currency == currency &&
            line.month.compareTo(advance.firstMonth) >= 0) {
          matured++;
        }
        for (final deduction in line.advances) {
          if (deduction.advanceId == advance.id) {
            taken += deduction.takenInCents;
          }
        }
      }
      (result[advance.staffMemberId] ??= []).add(
        PayrollAdvanceState(
          advanceId: advance.id,
          amountInCents: advance.amount.amountInCents,
          currency: currency,
          installments: advance.installments,
          firstMonth: advance.firstMonth,
          maturedMonths: matured,
          alreadyTaken: taken,
        ),
      );
    }
    return result;
  }

  /// Les retenues de [month] sur un brut de [grossInCents] en [currency],
  /// dans l'ordre du mois de départ puis de l'identifiant :
  /// - `k` = mois mûris + 1 — non borné : au-delà de `n`, l'avance est
  ///   **reportée** et tout le reste est dû ;
  /// - `dû` = `floor(montant × k ÷ n)` − déjà retenu ; une avance sans rien de
  ///   dû n'a pas de ligne ;
  /// - `pris` = `min(dû, brut restant)`, `report` = `dû − pris`.
  static List<PayrollLineAdvance> deduct({
    required String month,
    required String currency,
    required int grossInCents,
    required List<PayrollAdvanceState> states,
  }) {
    final ordered =
        states
            .where(
              (state) =>
                  state.currency == currency &&
                  state.firstMonth.compareTo(month) <= 0,
            )
            .toList()
          ..sort((a, b) {
            final byMonth = a.firstMonth.compareTo(b.firstMonth);
            return byMonth != 0 ? byMonth : a.advanceId.compareTo(b.advanceId);
          });
    var capacity = grossInCents;
    final result = <PayrollLineAdvance>[];
    for (final state in ordered) {
      final rank = state.maturedMonths + 1;
      final n = state.installments;
      final scheduled = rank >= n
          ? state.amountInCents
          : PayrollMath.floorDiv(state.amountInCents * rank, n);
      final due = scheduled - state.alreadyTaken;
      if (due <= 0) continue;
      final take = due < capacity ? due : capacity;
      capacity -= take;
      result.add(
        PayrollLineAdvance(
          advanceId: state.advanceId,
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
}
