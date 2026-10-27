import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_advance_request.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_arrear.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settlement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/salary_advance.dart';

/// Un mois de paie d'un agent : le livre du mois, sa ligne, son règlement.
class PayrollAgentMonth extends Equatable {
  final PayrollMonthView view;
  final PayrollLine line;

  const PayrollAgentMonth({required this.view, required this.line});

  String get month => view.month;

  PayrollPhase get phase => view.phase;

  /// Validée (ou versée) : les montants sont figés, le reste est une dette.
  bool get isLocked => phase.isLocked;

  PayrollSettlement get settlement => view.settlementOf(line);

  @override
  List<Object?> get props => [view, line];
}

/// Les cumuls d'une année civile, dans une devise, sur les mois validés.
class PayrollAgentTotals extends Equatable {
  final String currency;
  final int months;
  final int grossInCents;
  final int iprCnssInCents;
  final int absenceInCents;
  final int childcareInCents;
  final int advancesInCents;
  final int netInCents;
  final int paidInCents;

  const PayrollAgentTotals({
    required this.currency,
    this.months = 0,
    this.grossInCents = 0,
    this.iprCnssInCents = 0,
    this.absenceInCents = 0,
    this.childcareInCents = 0,
    this.advancesInCents = 0,
    this.netInCents = 0,
    this.paidInCents = 0,
  });

  PayrollAgentTotals add(PayrollAgentMonth month) {
    final line = month.line;
    final d = line.deductions;
    return PayrollAgentTotals(
      currency: currency,
      months: months + 1,
      grossInCents: grossInCents + line.grossInCents,
      iprCnssInCents: iprCnssInCents + d.iprInCents + d.cnssInCents,
      absenceInCents: absenceInCents + d.absenceInCents,
      childcareInCents: childcareInCents + d.childcareInCents,
      advancesInCents: advancesInCents + line.advanceInCents,
      netInCents: netInCents + line.netInCents,
      paidInCents: paidInCents + month.settlement.paidInCents,
    );
  }

  @override
  List<Object?> get props => [
    currency,
    months,
    grossInCents,
    iprCnssInCents,
    absenceInCents,
    childcareInCents,
    advancesInCents,
    netInCents,
    paidInCents,
  ];
}

/// Tout l'état de paie d'un agent, dérivé de la tablette — rien n'est stocké
/// en plus : la fiche est une vue sur le livre.
class PayrollAgentSituation extends Equatable {
  final String staffMemberId;

  /// L'année civile des cumuls, `YYYY`.
  final String year;

  /// Les mois où l'agent a une ligne, du plus récent au plus ancien.
  final List<PayrollAgentMonth> months;

  /// Ce que l'école doit encore sur les mois validés, par devise.
  final Map<String, int> outstanding;

  /// Les mois validés pas encore soldés.
  final int unsettledMonths;

  /// L'année civile, par devise (mois validés seuls).
  final List<PayrollAgentTotals> totals;

  /// Les avances nées (dépense payée, ou directes), la plus récente d'abord ;
  /// refusées et annulées comprises : elles se disent.
  final List<SalaryAdvance> advances;

  /// Les demandes encore dans le circuit de dépense, ou refusées.
  final List<PayrollAdvanceRequest> requests;

  /// Le registre des arriérés, pour cet agent ; `null` : aucun.
  final PayrollArrearsAgent? arrears;

  const PayrollAgentSituation({
    required this.staffMemberId,
    required this.year,
    required this.months,
    required this.outstanding,
    required this.unsettledMonths,
    required this.totals,
    required this.advances,
    required this.requests,
    required this.arrears,
  });

  /// Ce qui reste à rembourser sur les avances en cours, par devise.
  Map<String, int> get loansOutstanding {
    final result = <String, int>{};
    for (final advance in advances) {
      if (!advance.isOngoing) continue;
      final currency = advance.amount.currency;
      result[currency] = (result[currency] ?? 0) + advance.remainingInCents;
    }
    return result;
  }

  /// Le premier mois pas encore validé : son net est « prévu ».
  PayrollAgentMonth? get upcoming {
    for (final month in months) {
      if (!month.isLocked) return month;
    }
    return null;
  }

  PayrollAgentMonth? monthOf(String month) {
    for (final entry in months) {
      if (entry.month == month) return entry;
    }
    return null;
  }

  /// Les échéances de [advanceId] déjà retenues sur des mois validés.
  int installmentsTaken(String advanceId) => months
      .where((month) => month.isLocked)
      .where(
        (month) => month.line.advances.any(
          (a) => a.advanceId == advanceId && a.takenInCents > 0,
        ),
      )
      .length;

  /// L'échéance de [advanceId] sur le mois à venir, s'il y en a une.
  PayrollLineAdvance? nextInstallment(String advanceId) {
    for (final advance in upcoming?.line.advances ?? const []) {
      if (advance.advanceId == advanceId) return advance;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    staffMemberId,
    year,
    months,
    outstanding,
    unsettledMonths,
    totals,
    advances,
    requests,
    arrears,
  ];
}
