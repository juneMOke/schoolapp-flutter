import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/attendance_summary.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_advance_state.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/staff_pay_profile.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_advance_schedule.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_contract_picker.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_math.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_month.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Ce que le moteur lit pour un mois : que des faits.
class PayrollEngineInput {
  /// `YYYY-MM`.
  final String month;
  final PayrollSettings settings;

  /// Les agents de l'école et leurs périodes de contrat (avec montants).
  final Map<String, List<StaffContract>> contractsByMember;
  final Map<String, PayrollVariables> variables;
  final Map<String, StaffPayProfile> profiles;

  /// Le résumé du Pointage de M−1 ; `null` = mois hors année, vide (R1).
  final AttendanceSummary? attendance;

  /// Par agent : l'état de ses avances pour [month]
  /// (`PayrollAdvanceSchedule.statesOf`).
  final Map<String, List<PayrollAdvanceState>> advances;

  const PayrollEngineInput({
    required this.month,
    required this.settings,
    required this.contractsByMember,
    this.variables = const {},
    this.profiles = const {},
    this.attendance,
    this.advances = const {},
  });
}

/// Le livre calculé : une ligne par agent payé, et les agents sans contrat.
class PayrollComputation {
  final List<PayrollLine> lines;

  /// Les agents qui n'ont aucun contrat posé : « contrat à poser ».
  final List<String> withoutContract;

  const PayrollComputation({
    required this.lines,
    required this.withoutContract,
  });
}

/// Le moteur de paie : une fonction pure, en centimes, le même calcul que le
/// serveur (vecteurs de référence partagés).
///
/// ```text
/// base    PERMANENT amount · CONVENTIONNE bonus ou 0
///         VACATAIRE FORFAIT amount · HEURES roundDiv(minutes × taux, 60)
/// tauxHS  variable ?? (PERMANENT ? roundDiv(amount × ‰, diviseur × 1000 × pas)
///         × pas : défaut[devise])
/// hs      roundDiv(minutes_sup × tauxHS, 60)          (0 pour un vacataire)
/// alloc   enfants × allocation[devise]                (statuts éligibles)
/// net     brut − retenues d'avance                    (jamais négatif)
/// ```
abstract final class PayrollEngine {
  static PayrollComputation compute(PayrollEngineInput input) {
    final lines = <PayrollLine>[];
    final withoutContract = <String>[];
    for (final entry in input.contractsByMember.entries) {
      final contracts = entry.value;
      if (!contracts.any(PayrollContractPicker.isLive)) {
        withoutContract.add(entry.key);
        continue;
      }
      final contract = PayrollContractPicker.pick(contracts, input.month);
      if (contract == null) continue;
      lines.add(_line(input, entry.key, contract));
    }
    lines.sort((a, b) => a.staffMemberId.compareTo(b.staffMemberId));
    return PayrollComputation(lines: lines, withoutContract: withoutContract);
  }

  static PayrollLine _line(
    PayrollEngineInput input,
    String memberId,
    StaffContract contract,
  ) {
    final settings = input.settings;
    final kind = contract.kind;
    final hourly =
        kind == StaffContractKind.vacataire &&
        contract.payMode == StaffPayMode.hourly;
    final currency = currencyOf(contract, fallback: settings.firstCurrency);
    final amount = contract.amount?.amountInCents ?? 0;
    final perCurrency = settings.of(currency);
    final hoursMonth = PayrollMonth.previous(input.month);
    final summary =
        input.attendance?.of(memberId) ?? AttendanceAgentSummary.zero;

    final base = switch (kind) {
      StaffContractKind.conventionne => contract.bonus?.amountInCents ?? 0,
      StaffContractKind.vacataire when hourly => PayrollMath.roundDiv(
        summary.workedMinutes * amount,
        60,
      ),
      _ => amount,
    };

    final variables = input.variables[memberId];
    final overtimeAllowed = kind != StaffContractKind.vacataire;
    final overtimeMinutes = overtimeAllowed
        ? (variables?.overtimeMinutes ?? 0)
        : 0;
    final rate = overtimeAllowed
        ? variables?.overtimeRateInCents ??
              _defaultRate(kind, amount, settings, perCurrency)
        : 0;
    final overtime = PayrollMath.roundDiv(overtimeMinutes * rate, 60);

    final children =
        variables?.dependentChildren ??
        input.profiles[memberId]?.dependentChildren ??
        0;
    final allowance = settings.allowanceEligibleKinds.contains(kind)
        ? children * perCurrency.childAllowanceInCents
        : 0;

    final gross = base + overtime + allowance;
    final advances = PayrollAdvanceSchedule.deduct(
      month: input.month,
      currency: currency,
      grossInCents: gross,
      states: input.advances[memberId] ?? const [],
    );
    final taken = advances.fold(0, (sum, a) => sum + a.takenInCents);

    return PayrollLine(
      month: input.month,
      staffMemberId: memberId,
      contractId: contract.id,
      contractKind: kind,
      payMode: contract.payMode,
      contractFrom: contract.effectiveFrom,
      currency: currency,
      baseInCents: base,
      baseMinutes: hourly ? summary.workedMinutes : null,
      baseRateInCents: hourly ? amount : null,
      hoursMonth: hourly ? hoursMonth : null,
      overtimeMinutes: overtimeMinutes,
      overtimeRateInCents: rate,
      overtimeInCents: overtime,
      children: children,
      allowanceInCents: allowance,
      grossInCents: gross,
      advances: advances,
      netInCents: gross - taken,
      attendanceMonth: hoursMonth,
      attendance: summary,
    );
  }

  /// La devise de la ligne : celle de la prime pour un conventionné (son
  /// salaire est versé par l'État), celle du montant sinon. Une devise vide
  /// compte comme absente ; sans rien, [fallback] — la première devise que
  /// l'école a réglée.
  static String currencyOf(
    StaffContract contract, {
    String fallback = CurrencyCode.usd,
  }) {
    final candidates = contract.kind == StaffContractKind.conventionne
        ? [contract.bonus?.currency, contract.amount?.currency]
        : [contract.amount?.currency, contract.bonus?.currency];
    for (final candidate in candidates) {
      final code = CurrencyCode.normalize(candidate ?? '');
      if (code.isNotEmpty) return code;
    }
    return fallback;
  }

  /// Le taux horaire d'un permanent : salaire ÷ diviseur × majoration, arrondi
  /// au pas de la devise ; sinon le taux par défaut de la devise.
  static int _defaultRate(
    StaffContractKind? kind,
    int amount,
    PayrollSettings settings,
    PayrollCurrencySettings perCurrency,
  ) {
    if (kind != StaffContractKind.permanent) {
      return perCurrency.defaultOvertimeRateInCents;
    }
    final numerator = amount * settings.overtimeMultiplierPermille;
    final denominator = settings.monthlyHoursDivisor * 1000;
    final step = perCurrency.overtimeRateStepInCents;
    if (denominator <= 0) return 0;
    if (step <= 0) return PayrollMath.roundDiv(numerator, denominator);
    return PayrollMath.roundDiv(numerator, denominator * step) * step;
  }
}
