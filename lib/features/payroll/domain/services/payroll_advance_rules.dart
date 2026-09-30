import 'package:school_app_flutter/features/payroll/domain/entities/payroll_drafts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/salary_advance.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_contract_picker.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_engine.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_ledger.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_month.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';

/// Où en est une avance, pour le registre.
enum SalaryAdvancePhase { refused, cancelled, settled, upcoming, running }

/// Le statut d'une avance et, en cours, le rang de sa dernière échéance.
typedef SalaryAdvanceStatus = ({SalaryAdvancePhase phase, int rank});

/// Les règles d'une avance, partagées par l'octroi, l'annulation et l'écran
/// qui les annonce avant le geste.
abstract final class PayrollAdvanceRules {
  static const int maxInstallments = 4;

  /// Le mois où tombe la première échéance par défaut : le mois en cours si sa
  /// paie est encore en brouillon, sinon le suivant.
  static String defaultFirstMonth(PayrollSnapshot snapshot, String today) {
    final current = today.substring(0, 7);
    return PayrollLedger.monthView(snapshot, current).isEditable
        ? current
        : PayrollMonth.next(current);
  }

  /// Le contrat qui paiera l'agent au mois de départ : il fixe la devise.
  static StaffContract? contractFor(
    PayrollSnapshot snapshot,
    String staffMemberId,
    String month,
  ) => PayrollContractPicker.pick(
    snapshot.contractsByMember[staffMemberId] ?? const [],
    month,
  );

  static PayrollRule? refusalOf(
    PayrollSnapshot snapshot,
    SalaryAdvanceDraft draft,
  ) {
    if (draft.amount.amountInCents <= 0) return PayrollRule.invalidAmount;
    if (draft.installments < 1 || draft.installments > maxInstallments) {
      return PayrollRule.invalidInstallments;
    }
    final contract = contractFor(
      snapshot,
      draft.staffMemberId,
      draft.firstMonth,
    );
    if (contract == null) return PayrollRule.noContract;
    if (PayrollEngine.currencyOf(contract) != draft.amount.currency) {
      return PayrollRule.invalidAmount;
    }
    final view = PayrollLedger.monthView(snapshot, draft.firstMonth);
    if (view.phase != PayrollPhase.draft) return PayrollRule.monthLocked;
    return null;
  }

  /// Le statut d'[advance] au mois de [view] : refusée, annulée, soldée, à
  /// venir, ou en cours — avec le rang de l'échéance que le livre porte.
  static SalaryAdvanceStatus statusOf(
    SalaryAdvance advance,
    PayrollMonthView view,
  ) {
    final month = view.month;
    if (advance.isRefused) return (phase: SalaryAdvancePhase.refused, rank: 0);
    if (advance.isCancelled) {
      return (phase: SalaryAdvancePhase.cancelled, rank: 0);
    }
    if (advance.isSettled) return (phase: SalaryAdvancePhase.settled, rank: 0);
    if (advance.firstMonth.compareTo(month) > 0) {
      return (phase: SalaryAdvancePhase.upcoming, rank: 0);
    }
    for (final line in view.lines) {
      for (final deduction in line.advances) {
        if (deduction.advanceId == advance.id) {
          return (phase: SalaryAdvancePhase.running, rank: deduction.rank);
        }
      }
    }
    return (phase: SalaryAdvancePhase.running, rank: advance.installments);
  }

  /// Une retenue de cette avance est-elle déjà figée ?
  static bool hasFrozenDeduction(
    PayrollSnapshot snapshot,
    SalaryAdvance advance,
  ) =>
      advance.deductedInCents > 0 ||
      snapshot.frozenLines.values.any(
        (lines) => lines.any(
          (line) => line.advances.any(
            (deduction) =>
                deduction.advanceId == advance.id && deduction.takenInCents > 0,
          ),
        ),
      );
}
