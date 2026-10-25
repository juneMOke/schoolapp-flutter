import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/money/amount_input.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_settings_bounds.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/settings/payroll_settings_field_error.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

export 'package:school_app_flutter/features/payroll/presentation/widgets/settings/payroll_settings_field_error.dart';

/// Les montants d'une devise, dans l'ordre du formulaire.
enum PayrollCurrencyField { allowance, defaultRate, step, ipr }

/// Le barème en cours de saisie : les champs, leurs erreurs, et l'écart avec
/// le barème enregistré. Un champ montant vidé vaut zéro — rien n'est inventé.
class PayrollSettingsDraft extends ChangeNotifier {
  /// Les devises que l'école a réglées, dollar et franc d'abord : une devise
  /// qu'elle n'a pas réglée n'est pas inventée à l'enregistrement.
  final List<String> currencies;

  PayrollSettings _base;

  final TextEditingController hours = TextEditingController();
  final TextEditingController premium = TextEditingController();
  final TextEditingController days = TextEditingController();
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
  bool _absence = false;
  final Set<StaffContractKind> _eligible = {};

  PayrollSettingsDraft(PayrollSettings saved)
    : _base = saved,
      currencies = _currenciesOf(saved) {
    _fill(saved);
    for (final controller in _controllers) {
      controller.addListener(notifyListeners);
    }
  }

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

  /// Le barème enregistré a changé (synchronisation, enregistrement) : chaque
  /// champ que personne n'a touché prend la nouvelle valeur ; une saisie en
  /// cours n'est jamais écrasée — et un champ intact ne réécrit jamais
  /// l'ancienne valeur par-dessus celle d'un autre poste.
  void rebase(PayrollSettings saved) {
    if (saved.sameRulesAs(_base)) return;
    final before = _textsOf(_base);
    final after = _textsOf(saved);
    for (final entry in before.entries) {
      if (entry.key.text == entry.value) entry.key.text = after[entry.key]!;
    }
    if (_absence == _base.absenceDeductionEnabled) {
      _absence = saved.absenceDeductionEnabled;
    }
    if (_eligible.length == _base.allowanceEligibleKinds.length &&
        _eligible.containsAll(_base.allowanceEligibleKinds)) {
      _eligible
        ..clear()
        ..addAll(saved.allowanceEligibleKinds);
    }
    _base = saved;
    notifyListeners();
  }

  /// « Rétablir les valeurs par défaut » remplit le brouillon, à enregistrer.
  void resetToDefaults() => _fill(PayrollSettings.defaults);

  /// Le texte que chaque champ montre pour [settings].
  Map<TextEditingController, String> _textsOf(PayrollSettings settings) {
    final texts = <TextEditingController, String>{
      hours: '${settings.monthlyHoursDivisor}',
      premium: '${(settings.overtimeMultiplierPermille - 1000) ~/ 10}',
      days: '${settings.workDaysDivisor}',
    };
    for (final currency in currencies) {
      // Les défauts de la spec ne servent qu'à « Rétablir » : un barème servi
      // porte toujours ses devises.
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

  void _fill(PayrollSettings settings) {
    for (final entry in _textsOf(settings).entries) {
      entry.key.text = entry.value;
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
