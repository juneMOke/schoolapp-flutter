import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/money/amount_input.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_settings_bounds.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

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

/// Les montants d'une devise, dans l'ordre du formulaire.
enum PayrollCurrencyField { allowance, defaultRate, step, ipr }

/// Le barème en cours de saisie : les champs, leurs erreurs, et l'écart avec
/// le barème enregistré. Un champ montant vidé vaut zéro — rien n'est inventé.
class PayrollSettingsDraft extends ChangeNotifier {
  static const List<String> currencies = [CurrencyCode.usd, CurrencyCode.cdf];

  PayrollSettings _base;

  final TextEditingController hours = TextEditingController();
  final TextEditingController premium = TextEditingController();
  final TextEditingController days = TextEditingController();
  final Map<String, Map<PayrollCurrencyField, TextEditingController>> amounts =
      {
        for (final currency in currencies)
          currency: {
            for (final field in PayrollCurrencyField.values)
              field: TextEditingController(),
          },
      };
  final Map<String, TextEditingController> cnss = {
    for (final currency in currencies) currency: TextEditingController(),
  };
  bool _absence = false;
  final Set<StaffContractKind> _eligible = {};

  PayrollSettingsDraft(PayrollSettings saved) : _base = saved {
    _fill(saved);
    for (final controller in _controllers) {
      controller.addListener(notifyListeners);
    }
  }

  Iterable<TextEditingController> get _controllers => [
    hours,
    premium,
    days,
    for (final fields in amounts.values) ...fields.values,
    ...cnss.values,
  ];

  bool get absence => _absence;
  Set<StaffContractKind> get eligible => Set.unmodifiable(_eligible);

  void toggleAbsence() {
    _absence = !_absence;
    notifyListeners();
  }

  void toggleEligible(StaffContractKind kind) {
    if (!_eligible.remove(kind)) _eligible.add(kind);
    notifyListeners();
  }

  /// Le barème enregistré a changé (synchronisation, enregistrement) : une
  /// saisie en cours n'est jamais écrasée.
  void rebase(PayrollSettings saved) {
    if (saved.sameRulesAs(_base)) return;
    final untouched = !isDirty;
    _base = saved;
    if (untouched) _fill(saved);
  }

  /// « Rétablir les valeurs par défaut » remplit le brouillon, à enregistrer.
  void resetToDefaults() => _fill(PayrollSettings.defaults);

  void _fill(PayrollSettings settings) {
    hours.text = '${settings.monthlyHoursDivisor}';
    premium.text = '${(settings.overtimeMultiplierPermille - 1000) ~/ 10}';
    days.text = '${settings.workDaysDivisor}';
    for (final currency in currencies) {
      // Une devise que l'école n'a pas réglée part des valeurs de la spec :
      // un pas d'arrondi nul serait refusé par le serveur.
      final rules =
          settings.byCurrency[currency] ??
          PayrollSettings.defaults.of(currency);
      final cents = {
        PayrollCurrencyField.allowance: rules.childAllowanceInCents,
        PayrollCurrencyField.defaultRate: rules.defaultOvertimeRateInCents,
        PayrollCurrencyField.step: rules.overtimeRateStepInCents,
        PayrollCurrencyField.ipr: rules.iprFlatInCents,
      };
      for (final entry in cents.entries) {
        amounts[currency]![entry.key]!.text = MoneyFormat.amountOnly(
          Money(entry.value, currency),
        );
      }
      cnss[currency]!.text = '${rules.cnssPermille}';
    }
    _absence = settings.absenceDeductionEnabled;
    _eligible
      ..clear()
      ..addAll(settings.allowanceEligibleKinds);
    notifyListeners();
  }

  PayrollSettingsFieldError? errorOfHours() =>
      _intError(hours, PayrollSettingsBounds.monthlyHours);
  PayrollSettingsFieldError? errorOfPremium() =>
      _intError(premium, PayrollSettingsBounds.overtimePremiumPercent);
  PayrollSettingsFieldError? errorOfDays() =>
      _intError(days, PayrollSettingsBounds.workDays);
  PayrollSettingsFieldError? errorOfCnss(String currency) =>
      _intError(cnss[currency]!, PayrollSettingsBounds.cnssPermille);

  PayrollSettingsFieldError? errorOfAmount(
    String currency,
    PayrollCurrencyField field,
  ) {
    final cents = _cents(amounts[currency]![field]!);
    if (cents == null) return const PayrollSettingsBadAmount();
    if (field == PayrollCurrencyField.step &&
        cents < PayrollSettingsBounds.minOvertimeStepInCents) {
      return const PayrollSettingsBelowMin();
    }
    return null;
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

  /// Vide ou zéro vaut 0 ; sinon le montant lu, ou `null` s'il est illisible.
  static int? _cents(TextEditingController controller) {
    final raw = controller.text.trim();
    if (RegExp(r'^[0\s.,]*$').hasMatch(raw)) return 0;
    return AmountInput.toCents(raw);
  }

  bool get hasErrors =>
      errorOfHours() != null ||
      errorOfPremium() != null ||
      errorOfDays() != null ||
      currencies.any(
        (currency) =>
            errorOfCnss(currency) != null ||
            PayrollCurrencyField.values.any(
              (field) => errorOfAmount(currency, field) != null,
            ),
      );

  /// Le barème saisi, ou `null` tant qu'un champ est en erreur.
  PayrollSettings? get settings {
    if (hasErrors) return null;
    final premiumPercent = int.parse(premium.text.trim());
    final unchangedPremium =
        premiumPercent == (_base.overtimeMultiplierPermille - 1000) ~/ 10;
    int cents(String currency, PayrollCurrencyField field) =>
        _cents(amounts[currency]![field]!)!;
    return _base.copyWith(
      monthlyHoursDivisor: int.parse(hours.text.trim()),
      // Une majoration réglée au pour mille près (1325) n'est pas arrondie
      // tant que personne ne touche au champ.
      overtimeMultiplierPermille: unchangedPremium
          ? _base.overtimeMultiplierPermille
          : 1000 + premiumPercent * 10,
      workDaysDivisor: int.parse(days.text.trim()),
      absenceDeductionEnabled: _absence,
      allowanceEligibleKinds: {..._eligible},
      // Une devise hors du formulaire garde ses règles.
      byCurrency: {
        ..._base.byCurrency,
        for (final currency in currencies)
          currency: PayrollCurrencySettings(
            childAllowanceInCents: cents(
              currency,
              PayrollCurrencyField.allowance,
            ),
            defaultOvertimeRateInCents: cents(
              currency,
              PayrollCurrencyField.defaultRate,
            ),
            overtimeRateStepInCents: cents(currency, PayrollCurrencyField.step),
            iprFlatInCents: cents(currency, PayrollCurrencyField.ipr),
            cnssPermille: int.parse(cnss[currency]!.text.trim()),
          ),
      },
    );
  }

  /// Un champ en erreur est une modification : on ne quitte pas sans le dire.
  bool get isDirty => settings?.sameRulesAs(_base) != true;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
