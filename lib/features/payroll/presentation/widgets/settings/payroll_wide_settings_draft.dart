import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_settings_bounds.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/settings/payroll_settings_field_error.dart';

/// Les champs du barème élargi (Q8) : charges patronales, plafonds d'avance,
/// intitulés du bulletin. Montrés — et donc saisis — seulement une fois que
/// le serveur les a servis ; la PC/E activable vit avec eux.
class PayrollWideSettingsDraft {
  final TextEditingController cnssEmployer = TextEditingController();
  final TextEditingController inpp = TextEditingController();
  final TextEditingController onem = TextEditingController();
  final TextEditingController advanceMax = TextEditingController();
  final TextEditingController loanMax = TextEditingController();
  final TextEditingController beneficiaryLabel = TextEditingController();
  final TextEditingController directorLabel = TextEditingController();
  final TextEditingController cashierLabel = TextEditingController();
  bool childcare = true;

  List<TextEditingController> get controllers => [
    cnssEmployer,
    inpp,
    onem,
    advanceMax,
    loanMax,
    beneficiaryLabel,
    directorLabel,
    cashierLabel,
  ];

  /// Le texte que chaque champ montre pour [settings].
  Map<TextEditingController, String> textsOf(PayrollSettings settings) => {
    cnssEmployer: '${settings.cnssEmployerPermille}',
    inpp: '${settings.inppPermille}',
    onem: '${settings.onemPermille}',
    advanceMax: '${settings.advanceMaxPercent}',
    loanMax: '${settings.loanMaxMonths}',
    beneficiaryLabel: settings.signatureBeneficiaryLabel ?? '',
    directorLabel: settings.signatureDirectorLabel ?? '',
    cashierLabel: settings.signatureCashierLabel ?? '',
  };

  PayrollSettingsFieldError? errorOfPermille(TextEditingController field) =>
      _intError(field, PayrollSettingsBounds.employerPermille);
  PayrollSettingsFieldError? errorOfAdvanceMax() =>
      _intError(advanceMax, PayrollSettingsBounds.advanceMaxPercent);
  PayrollSettingsFieldError? errorOfLoanMax() =>
      _intError(loanMax, PayrollSettingsBounds.loanMaxMonths);
  PayrollSettingsFieldError? errorOfLabel(TextEditingController field) =>
      field.text.trim().length > PayrollSettingsBounds.maxSignatureLabel
      ? const PayrollSettingsLabelTooLong(
          PayrollSettingsBounds.maxSignatureLabel,
        )
      : null;

  bool get hasErrors =>
      [cnssEmployer, inpp, onem].any((f) => errorOfPermille(f) != null) ||
      errorOfAdvanceMax() != null ||
      errorOfLoanMax() != null ||
      [
        beneficiaryLabel,
        directorLabel,
        cashierLabel,
      ].any((f) => errorOfLabel(f) != null);

  /// [settings] avec les valeurs saisies — à n'appeler que sans erreur.
  PayrollSettings applyTo(PayrollSettings settings) {
    String? label(TextEditingController field) {
      final text = field.text.trim();
      return text.isEmpty ? null : text;
    }

    return settings.copyWith(
      cnssEmployerPermille: int.parse(cnssEmployer.text.trim()),
      inppPermille: int.parse(inpp.text.trim()),
      onemPermille: int.parse(onem.text.trim()),
      advanceMaxPercent: int.parse(advanceMax.text.trim()),
      loanMaxMonths: int.parse(loanMax.text.trim()),
      childcareEnabled: childcare,
      signatures: (
        beneficiary: label(beneficiaryLabel),
        director: label(directorLabel),
        cashier: label(cashierLabel),
      ),
    );
  }

  static PayrollSettingsFieldError? _intError(
    TextEditingController controller,
    PayrollIntRange range,
  ) {
    final value = int.tryParse(controller.text.trim());
    return value != null && range.contains(value)
        ? null
        : PayrollSettingsOutOfRange(range);
  }
}
