/// Une devise des réglages de paie, telle que le socle la sert. Centimes.
typedef PayrollCurrencySeed = ({
  String currency,
  int childAllowanceInCents,
  int defaultOvertimeRateInCents,
  int overtimeRateStepInCents,
  int iprFlatInCents,
  int cnssPermille,
});

/// Une rubrique de retenue de l'école, telle que le socle la sert
/// (`deductionTypes[]`, archivées comprises).
typedef PayrollDeductionTypeSeed = ({
  String id,
  String code,
  String label,
  String? description,
  String currency,
  int defaultAmountInCents,
  int sortOrder,
  bool archived,
  String? clientUpdatedAt,
});

/// Les réglages de paie d'une école tels que le socle les sert (section
/// `payrollSettings`, `PayrollSettingsDto` du serveur — la liste des devises
/// s'y nomme `currencyRules`, comme dans le PUT et les vecteurs) : diviseur mensuel, majoration en ‰, statuts ouvrant les
/// allocations, et par devise l'allocation par enfant, le taux d'heure sup.
/// par défaut et son pas ; en v2, le diviseur de jours, la retenue d'absence,
/// et par devise le forfait IPR et la CNSS en ‰.
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

  /// v2 — jours d'un mois plein et retenue d'absence. Un serveur v1 ne les
  /// sert pas : 26 jours, retenue coupée.
  final int workDaysDivisor;
  final bool absenceDeductionEnabled;

  /// Q8 — charges patronales (‰), plafonds d'avance, PC/E, intitulés du
  /// bulletin. **Tous `null` tant que le serveur ne les a pas servis** : la
  /// remontée les tait alors (le PUT garde une valeur absente), pour qu'une
  /// tablette au cache ancien ne rallume pas, par ses défauts, la PC/E d'une
  /// école qui l'a coupée.
  final int? cnssEmployerPermille;
  final int? inppPermille;
  final int? onemPermille;
  final int? advanceMaxPercent;
  final int? loanMaxMonths;
  final bool? childcareEnabled;

  /// `null` tant que le serveur ne les sert pas : retenue active, et le champ
  /// reste tu à la remontée.
  final bool? legalDeductionsEnabled;
  final bool? salaryAdvancesEnabled;
  final bool? staffLoansEnabled;
  final String? signatureBeneficiaryLabel;
  final String? signatureDirectorLabel;
  final String? signatureCashierLabel;

  /// Le catalogue des rubriques. `null` : le champ n'est pas servi, le cache
  /// reste ; une liste vide, elle, dit que l'école n'a aucune rubrique.
  final List<PayrollDeductionTypeSeed>? deductionTypes;

  const PayrollSettingsSeed({
    required this.monthlyHoursDivisor,
    required this.overtimeMultiplierPermille,
    required this.allowanceEligibleKinds,
    required this.byCurrency,
    this.workDaysDivisor = 26,
    this.absenceDeductionEnabled = false,
    this.cnssEmployerPermille,
    this.inppPermille,
    this.onemPermille,
    this.advanceMaxPercent,
    this.loanMaxMonths,
    this.childcareEnabled,
    this.legalDeductionsEnabled,
    this.salaryAdvancesEnabled,
    this.staffLoansEnabled,
    this.signatureBeneficiaryLabel,
    this.signatureDirectorLabel,
    this.signatureCashierLabel,
    this.deductionTypes,
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
    final currencies = raw['currencyRules'];
    final days = raw['workDaysDivisor'];
    final absence = raw['absenceDeductionEnabled'];
    final wide = raw['childcareEnabled'] is bool;
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
      workDaysDivisor: days is num && days >= 1 && days <= 31
          ? days.toInt()
          : 26,
      absenceDeductionEnabled: absence == true,
      cnssEmployerPermille: wide
          ? _within(raw['cnssEmployerPermille'], 0, 1000, 130)
          : null,
      inppPermille: wide ? _within(raw['inppPermille'], 0, 1000, 20) : null,
      onemPermille: wide ? _within(raw['onemPermille'], 0, 1000, 2) : null,
      advanceMaxPercent: wide
          ? _within(raw['advanceMaxPercent'], 10, 100, 50)
          : null,
      loanMaxMonths: wide ? _within(raw['loanMaxMonths'], 2, 12, 4) : null,
      childcareEnabled: wide ? raw['childcareEnabled'] != false : null,
      legalDeductionsEnabled: _switch(raw['legalDeductionsEnabled']),
      salaryAdvancesEnabled: _switch(raw['salaryAdvancesEnabled']),
      staffLoansEnabled: _switch(raw['staffLoansEnabled']),
      signatureBeneficiaryLabel: _label(raw['signatureBeneficiaryLabel']),
      signatureDirectorLabel: _label(raw['signatureDirectorLabel']),
      signatureCashierLabel: _label(raw['signatureCashierLabel']),
      deductionTypes: _deductionTypes(raw['deductionTypes']),
    );
  }

  /// `null` si le champ manque ou si une rubrique est illisible : la liste
  /// fait foi, et une liste tronquée retirerait des rubriques.
  static List<PayrollDeductionTypeSeed>? _deductionTypes(Object? raw) {
    if (raw is! List) return null;
    final types = <PayrollDeductionTypeSeed>[];
    for (final item in raw) {
      if (item is! Map) return null;
      final id = item['id'];
      final label = item['label'];
      final order = item['sortOrder'];
      if (id is! String ||
          id.trim().isEmpty ||
          label is! String ||
          order is! num) {
        return null;
      }
      final at = item['clientUpdatedAt'];
      final code = item['code'];
      final description = item['description'];
      final currency = item['currency'];
      final defaultAmount = item['defaultAmountInCents'];
      types.add((
        id: id.trim().toLowerCase(),
        code: code is String ? code : '',
        label: label,
        description: description is String ? description : null,
        currency: currency is String ? currency : '',
        defaultAmountInCents: defaultAmount is num ? defaultAmount.toInt() : 0,
        sortOrder: order.toInt(),
        archived: item['archived'] == true,
        clientUpdatedAt: at is String ? at : null,
      ));
    }
    return types;
  }

  static bool? _switch(Object? raw) => raw is bool ? raw : null;

  /// Le serveur sert-il les réglages Q8 ? Il les sert toujours ensemble.
  bool get servesWideSettings => childcareEnabled != null;

  /// Un entier du fil dans ses bornes ; absent ou hors bornes, le défaut.
  static int _within(Object? raw, int min, int max, int fallback) =>
      raw is num && raw >= min && raw <= max ? raw.toInt() : fallback;

  /// Un intitulé non vide, ou `null` (celui du modèle papier).
  static String? _label(Object? raw) =>
      raw is String && raw.trim().isNotEmpty ? raw.trim() : null;

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
      iprFlatInCents: _count(raw['iprFlatInCents']),
      cnssPermille: _count(raw['cnssPermille']),
    );
  }

  /// Un entier positif du fil ; absent ou illisible = 0, la valeur v1.
  static int _count(Object? raw) {
    if (raw is! num || raw < 0) return 0;
    return raw.toInt();
  }

  /// La forme du fil, pour la remontée comme pour la mise en cache.
  Map<String, dynamic> toJson() => {
    'monthlyHoursDivisor': monthlyHoursDivisor,
    'overtimeMultiplierPermille': overtimeMultiplierPermille,
    'allowanceEligibleKinds': allowanceEligibleKinds,
    'workDaysDivisor': workDaysDivisor,
    'absenceDeductionEnabled': absenceDeductionEnabled,
    'legalDeductionsEnabled': ?legalDeductionsEnabled,
    'salaryAdvancesEnabled': ?salaryAdvancesEnabled,
    'staffLoansEnabled': ?staffLoansEnabled,
    if (servesWideSettings) ...{
      'cnssEmployerPermille': cnssEmployerPermille,
      'inppPermille': inppPermille,
      'onemPermille': onemPermille,
      'advanceMaxPercent': advanceMaxPercent,
      'loanMaxMonths': loanMaxMonths,
      'childcareEnabled': childcareEnabled,
      // Une chaîne vide revient à l'intitulé par défaut (le PUT garde une
      // valeur `null` : l'effacer, c'est l'envoyer vide).
      'signatureBeneficiaryLabel': signatureBeneficiaryLabel ?? '',
      'signatureDirectorLabel': signatureDirectorLabel ?? '',
      'signatureCashierLabel': signatureCashierLabel ?? '',
    },
    'currencyRules': [
      for (final seed in byCurrency)
        {
          'currency': seed.currency,
          'childAllowanceInCents': seed.childAllowanceInCents,
          'defaultOvertimeRateInCents': seed.defaultOvertimeRateInCents,
          'overtimeRateStepInCents': seed.overtimeRateStepInCents,
          'iprFlatInCents': seed.iprFlatInCents,
          'cnssPermille': seed.cnssPermille,
        },
    ],
  };
}
