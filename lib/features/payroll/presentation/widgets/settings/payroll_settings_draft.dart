import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_settings_bounds.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/settings/payroll_currency_settings_draft.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/settings/payroll_settings_field_error.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/settings/payroll_wide_settings_draft.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

export 'package:school_app_flutter/features/payroll/presentation/widgets/settings/payroll_currency_settings_draft.dart'
    show PayrollCurrencyField;
export 'package:school_app_flutter/features/payroll/presentation/widgets/settings/payroll_settings_field_error.dart';

/// Le barème en cours de saisie : les champs, leurs erreurs, et l'écart avec
/// le barème enregistré. Un champ montant vidé vaut zéro — rien n'est inventé.
class PayrollSettingsDraft extends ChangeNotifier {
  PayrollSettings _base;

  final TextEditingController hours = TextEditingController();
  final TextEditingController premium = TextEditingController();
  final TextEditingController days = TextEditingController();

  /// Les règles par devise : seules celles que l'école a réglées.
  final PayrollCurrencySettingsDraft money;

  /// Le barème élargi (Q8), saisi seulement quand le serveur l'a servi.
  final PayrollWideSettingsDraft wide = PayrollWideSettingsDraft();
  bool _absence = false;
  final Set<StaffContractKind> _eligible = {};

  PayrollSettingsDraft(PayrollSettings saved)
    : _base = saved,
      money = PayrollCurrencySettingsDraft(saved) {
    _fill(saved);
    for (final controller in _controllers) {
      controller.addListener(notifyListeners);
    }
  }

  List<String> get currencies => money.currencies;
  Map<String, Map<PayrollCurrencyField, TextEditingController>> get amounts =>
      money.amounts;
  Map<String, TextEditingController> get cnss => money.cnss;
  bool get showsWide => _base.wideSettingsServed;

  Iterable<TextEditingController> get _controllers => [
    hours,
    premium,
    days,
    ...money.controllers,
    ...wide.controllers,
  ];

  bool get absence => _absence;
  Set<StaffContractKind> get eligible => Set.unmodifiable(_eligible);

  void toggleChildcare() {
    wide.childcare = !wide.childcare;
    notifyListeners();
  }

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
    if (wide.childcare == _base.childcareEnabled) {
      wide.childcare = saved.childcareEnabled;
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
  Map<TextEditingController, String> _textsOf(PayrollSettings settings) => {
    hours: '${settings.monthlyHoursDivisor}',
    premium: '${(settings.overtimeMultiplierPermille - 1000) ~/ 10}',
    days: '${settings.workDaysDivisor}',
    ...money.textsOf(settings),
    ...wide.textsOf(settings),
  };

  void _fill(PayrollSettings settings) {
    for (final entry in _textsOf(settings).entries) {
      entry.key.text = entry.value;
    }
    _absence = settings.absenceDeductionEnabled;
    wide.childcare = settings.childcareEnabled;
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
      money.errorOfCnss(currency);
  PayrollSettingsFieldError? errorOfAmount(
    String currency,
    PayrollCurrencyField field,
  ) => money.errorOfAmount(currency, field);

  static PayrollSettingsFieldError? _intError(
    TextEditingController controller,
    PayrollIntRange range,
  ) {
    final value = int.tryParse(controller.text.trim());
    return value != null && range.contains(value)
        ? null
        : PayrollSettingsOutOfRange(range);
  }

  bool get hasErrors =>
      errorOfHours() != null ||
      errorOfPremium() != null ||
      errorOfDays() != null ||
      money.hasErrors ||
      (showsWide && wide.hasErrors);

  /// Le barème saisi, ou `null` tant qu'un champ est en erreur.
  PayrollSettings? get settings {
    if (hasErrors) return null;
    final premiumPercent = int.parse(premium.text.trim());
    final unchangedPremium =
        premiumPercent == (_base.overtimeMultiplierPermille - 1000) ~/ 10;
    final edited = _base.copyWith(
      monthlyHoursDivisor: int.parse(hours.text.trim()),
      // Une majoration réglée au pour mille près (1325) n'est pas arrondie
      // tant que personne ne touche au champ.
      overtimeMultiplierPermille: unchangedPremium
          ? _base.overtimeMultiplierPermille
          : 1000 + premiumPercent * 10,
      workDaysDivisor: int.parse(days.text.trim()),
      absenceDeductionEnabled: _absence,
      allowanceEligibleKinds: {..._eligible},
      byCurrency: money.byCurrency(_base),
    );
    return showsWide ? wide.applyTo(edited) : edited;
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
