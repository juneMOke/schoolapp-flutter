/// Une devise des réglages de paie, telle que le socle la sert. Centimes.
typedef PayrollCurrencySeed = ({
  String currency,
  int childAllowanceInCents,
  int defaultOvertimeRateInCents,
  int overtimeRateStepInCents,
});

/// Les réglages de paie d'une école tels que le socle les sert (section
/// `payrollSettings`) : diviseur mensuel, majoration en ‰, statuts ouvrant les
/// allocations, et par devise l'allocation par enfant, le taux d'heure sup.
/// par défaut et son pas.
///
/// Vit dans le socle et non dans le module Paie, pour la même raison que
/// `StaffAttendanceSettingsSeed` : la descente du référentiel ne doit importer
/// aucun module métier — elle reçoit une fonction qui range ces valeurs.
class PayrollSettingsSeed {
  final int monthlyHoursDivisor;
  final int overtimeMultiplierPermille;

  /// Valeurs du fil (`PERMANENT`, `VACATAIRE`, `CONVENTIONNE`).
  final List<String> allowanceEligibleKinds;
  final List<PayrollCurrencySeed> byCurrency;

  const PayrollSettingsSeed({
    required this.monthlyHoursDivisor,
    required this.overtimeMultiplierPermille,
    required this.allowanceEligibleKinds,
    required this.byCurrency,
  });

  /// La section du socle, ou `null` quand elle n'est pas communiquée ou
  /// illisible : le cache reste alors tel quel.
  static PayrollSettingsSeed? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final inner = raw['settings'];
    if (inner is Map) return tryParse(inner);
    final divisor = raw['monthlyHoursDivisor'];
    final permille = raw['overtimeMultiplierPermille'];
    final kinds = raw['allowanceEligibleKinds'];
    final currencies = raw['byCurrency'];
    if (divisor is! num ||
        divisor <= 0 ||
        permille is! num ||
        kinds is! List ||
        currencies is! List) {
      return null;
    }
    return PayrollSettingsSeed(
      monthlyHoursDivisor: divisor.toInt(),
      overtimeMultiplierPermille: permille.toInt(),
      allowanceEligibleKinds: [
        for (final kind in kinds)
          if (kind is String && kind.trim().isNotEmpty) kind.trim(),
      ],
      byCurrency: [
        for (final item in currencies)
          if (_currency(item) case final PayrollCurrencySeed seed) seed,
      ],
    );
  }

  static PayrollCurrencySeed? _currency(Object? raw) {
    if (raw is! Map) return null;
    final code = raw['currency'];
    final allowance = raw['childAllowanceInCents'];
    final rate = raw['defaultOvertimeRateInCents'];
    final step = raw['overtimeRateStepInCents'];
    if (code is! String ||
        code.trim().isEmpty ||
        allowance is! num ||
        rate is! num ||
        step is! num) {
      return null;
    }
    return (
      currency: code.trim().toUpperCase(),
      childAllowanceInCents: allowance.toInt(),
      defaultOvertimeRateInCents: rate.toInt(),
      overtimeRateStepInCents: step.toInt(),
    );
  }

  /// La forme du fil, pour la remontée comme pour la mise en cache.
  Map<String, dynamic> toJson() => {
    'monthlyHoursDivisor': monthlyHoursDivisor,
    'overtimeMultiplierPermille': overtimeMultiplierPermille,
    'allowanceEligibleKinds': allowanceEligibleKinds,
    'byCurrency': [
      for (final seed in byCurrency)
        {
          'currency': seed.currency,
          'childAllowanceInCents': seed.childAllowanceInCents,
          'defaultOvertimeRateInCents': seed.defaultOvertimeRateInCents,
          'overtimeRateStepInCents': seed.overtimeRateStepInCents,
        },
    ],
  };
}
