import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';

/// Une borne entière inclusive.
class PayrollIntRange {
  final int min;
  final int max;

  const PayrollIntRange(this.min, this.max);

  bool contains(int value) => value >= min && value <= max;
}

/// Les bornes que le serveur pose sur le barème (`PayrollSettingsInput`) : le
/// formulaire les montre champ par champ, le cas d'usage les rejoue avant
/// d'écrire — un barème hors bornes ne part jamais dans la file.
abstract final class PayrollSettingsBounds {
  /// Heures d'un mois de salaire.
  static const PayrollIntRange monthlyHours = PayrollIntRange(1, 744);

  /// Majoration des heures sup., en pour mille (× 1 à × 5).
  static const PayrollIntRange overtimeMultiplierPermille = PayrollIntRange(
    1000,
    5000,
  );

  /// La même, saisie en pour cent au-dessus du taux.
  static const PayrollIntRange overtimePremiumPercent = PayrollIntRange(0, 400);

  /// CNSS de l'agent, en pour mille de la base.
  static const PayrollIntRange cnssPermille = PayrollIntRange(0, 1000);

  /// Le pas d'arrondi d'un taux d'heure sup. : un centime au moins.
  static const int minOvertimeStepInCents = 1;

  /// Q8 — une charge patronale, en pour mille.
  static const PayrollIntRange employerPermille = PayrollIntRange(0, 1000);

  /// Q8 — le plafond d'une échéance d'avance, en % du salaire de base.
  static const PayrollIntRange advanceMaxPercent = PayrollIntRange(10, 100);

  /// Q8 — les échéances d'un prêt au plus.
  static const PayrollIntRange loanMaxMonths = PayrollIntRange(2, 12);

  /// Q8 — un intitulé de signature du bulletin, en caractères.
  static const int maxSignatureLabel = 40;

  static bool isValid(PayrollSettings settings) =>
      monthlyHours.contains(settings.monthlyHoursDivisor) &&
      overtimeMultiplierPermille.contains(
        settings.overtimeMultiplierPermille,
      ) &&
      settings.byCurrency.values.every(
        (currency) =>
            currency.childAllowanceInCents >= 0 &&
            currency.defaultOvertimeRateInCents >= 0 &&
            currency.overtimeRateStepInCents >= minOvertimeStepInCents &&
            currency.iprFlatInCents >= 0 &&
            cnssPermille.contains(currency.cnssPermille),
      ) &&
      (!settings.wideSettingsServed || _wideValid(settings));

  static bool _wideValid(PayrollSettings settings) =>
      employerPermille.contains(settings.cnssEmployerPermille) &&
      employerPermille.contains(settings.inppPermille) &&
      employerPermille.contains(settings.onemPermille) &&
      advanceMaxPercent.contains(settings.advanceMaxPercent) &&
      loanMaxMonths.contains(settings.loanMaxMonths) &&
      [
        settings.signatureBeneficiaryLabel,
        settings.signatureDirectorLabel,
        settings.signatureCashierLabel,
      ].every((label) => (label?.length ?? 0) <= maxSignatureLabel);
}
