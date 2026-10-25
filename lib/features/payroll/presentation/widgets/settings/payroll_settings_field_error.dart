import 'package:school_app_flutter/features/payroll/domain/services/payroll_settings_bounds.dart';

/// Ce qui ne va pas dans un champ du barème.
sealed class PayrollSettingsFieldError {
  const PayrollSettingsFieldError();
}

/// Un entier hors de ses bornes, ou illisible.
class PayrollSettingsOutOfRange extends PayrollSettingsFieldError {
  final PayrollIntRange range;
  const PayrollSettingsOutOfRange(this.range);
}

/// Un montant illisible.
class PayrollSettingsBadAmount extends PayrollSettingsFieldError {
  const PayrollSettingsBadAmount();
}

/// Un montant sous son plancher (le pas d'arrondi : un centime au moins).
class PayrollSettingsBelowMin extends PayrollSettingsFieldError {
  const PayrollSettingsBelowMin();
}

/// Un intitulé plus long que ce que le bulletin imprime.
class PayrollSettingsLabelTooLong extends PayrollSettingsFieldError {
  final int max;
  const PayrollSettingsLabelTooLong(this.max);
}
