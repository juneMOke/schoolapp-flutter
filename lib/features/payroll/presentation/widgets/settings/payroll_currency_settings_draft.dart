import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/money/amount_input.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_settings_bounds.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/settings/payroll_settings_field_error.dart';

/// Les montants d'une devise, dans l'ordre du formulaire.
enum PayrollCurrencyField { allowance, defaultRate, step, ipr }

/// Les règles par devise du barème en cours de saisie : allocation, taux
/// d'heure sup., pas, IPR, CNSS. Seules les devises que l'école a réglées —
/// dollar et franc d'abord — : une devise non réglée n'est pas inventée.
class PayrollCurrencySettingsDraft {
  final List<String> currencies;

  PayrollCurrencySettingsDraft(PayrollSettings saved)
    : currencies = _currenciesOf(saved);

  late final Map<String, Map<PayrollCurrencyField, TextEditingController>>
  amounts = {
    for (final currency in currencies)
      currency: {
        for (final field in PayrollCurrencyField.values)
          field: TextEditingController(),
      },
  };
  late final Map<String, TextEditingController> cnss = {
    for (final currency in currencies) currency: TextEditingController(),
  };

  static List<String> _currenciesOf(PayrollSettings settings) {
    const first = [CurrencyCode.usd, CurrencyCode.cdf];
    final set = settings.byCurrency.keys.toSet();
    if (set.isEmpty) return const [CurrencyCode.usd];
    return [
      for (final code in first)
        if (set.contains(code)) code,
      ...(set.difference(first.toSet()).toList()..sort()),
    ];
  }

  List<TextEditingController> get controllers => [
    for (final fields in amounts.values) ...fields.values,
    ...cnss.values,
  ];

  /// Le texte que chaque champ montre pour [settings]. Les défauts de la spec
  /// ne servent qu'à « Rétablir » : un barème servi porte ses devises.
  Map<TextEditingController, String> textsOf(PayrollSettings settings) {
    final texts = <TextEditingController, String>{};
    for (final currency in currencies) {
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
        texts[amounts[currency]![entry.key]!] = MoneyFormat.amountOnly(
          Money(entry.value, currency),
        );
      }
      texts[cnss[currency]!] = '${rules.cnssPermille}';
    }
    return texts;
  }

  PayrollSettingsFieldError? errorOfCnss(String currency) {
    final value = int.tryParse(cnss[currency]!.text.trim());
    return value != null && PayrollSettingsBounds.cnssPermille.contains(value)
        ? null
        : const PayrollSettingsOutOfRange(PayrollSettingsBounds.cnssPermille);
  }

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

  bool get hasErrors => currencies.any(
    (currency) =>
        errorOfCnss(currency) != null ||
        PayrollCurrencyField.values.any(
          (field) => errorOfAmount(currency, field) != null,
        ),
  );

  /// Les règles saisies, celles d'une devise hors du formulaire gardées — à
  /// n'appeler que sans erreur.
  Map<String, PayrollCurrencySettings> byCurrency(PayrollSettings base) {
    int cents(String currency, PayrollCurrencyField field) =>
        _cents(amounts[currency]![field]!)!;
    return {
      ...base.byCurrency,
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
    };
  }

  /// Vide ou zéro vaut 0 ; sinon le montant lu, ou `null` s'il est illisible.
  static int? _cents(TextEditingController controller) {
    final raw = controller.text.trim();
    if (RegExp(r'^[0\s.,]*$').hasMatch(raw)) return 0;
    return AmountInput.toCents(raw);
  }
}
