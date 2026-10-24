import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Les réglages d'une devise : allocation par enfant, taux d'heure sup. par
/// défaut, le pas auquel s'arrondit un taux calculé, et les retenues légales
/// v2 — le forfait IPR par agent payé et la CNSS en ‰ de la base. Centimes.
class PayrollCurrencySettings extends Equatable {
  final int childAllowanceInCents;
  final int defaultOvertimeRateInCents;
  final int overtimeRateStepInCents;

  /// Retenu une fois sur chaque agent dont le brut est positif (T3).
  final int iprFlatInCents;

  /// Pour mille de la base de la ligne, avant l'absence (T4).
  final int cnssPermille;

  const PayrollCurrencySettings({
    required this.childAllowanceInCents,
    required this.defaultOvertimeRateInCents,
    required this.overtimeRateStepInCents,
    this.iprFlatInCents = 0,
    this.cnssPermille = 0,
  });

  /// Une devise que l'école n'a pas réglée : rien n'est inventé.
  static const PayrollCurrencySettings none = PayrollCurrencySettings(
    childAllowanceInCents: 0,
    defaultOvertimeRateInCents: 0,
    overtimeRateStepInCents: 0,
  );

  @override
  List<Object?> get props => [
    childAllowanceInCents,
    defaultOvertimeRateInCents,
    overtimeRateStepInCents,
    iprFlatInCents,
    cnssPermille,
  ];
}

/// Les réglages de paie d'une école. Entiers seulement : la majoration est en
/// pour mille, jamais un flottant qui arrondirait autrement en Java.
class PayrollSettings extends Equatable {
  /// Heures d'un mois plein, pour le taux horaire d'un permanent.
  final int monthlyHoursDivisor;

  /// 1300 = +30 %.
  final int overtimeMultiplierPermille;

  /// Les statuts qui ouvrent les allocations familiales de l'école.
  final Set<StaffContractKind> allowanceEligibleKinds;

  /// Jours d'un mois plein pour la retenue d'absence (T5) — distinct de
  /// [monthlyHoursDivisor], qui compte des heures.
  final int workDaysDivisor;

  /// Coupée par défaut : une école qui ne règle rien est payée comme en v1.
  final bool absenceDeductionEnabled;

  /// Par code ISO.
  final Map<String, PayrollCurrencySettings> byCurrency;
  final RecordSyncState syncState;

  const PayrollSettings({
    required this.monthlyHoursDivisor,
    required this.overtimeMultiplierPermille,
    required this.allowanceEligibleKinds,
    required this.byCurrency,
    this.workDaysDivisor = defaultWorkDaysDivisor,
    this.absenceDeductionEnabled = false,
    this.syncState = RecordSyncState.synced,
  });

  static const int defaultWorkDaysDivisor = 26;

  /// Les bornes du diviseur de jours que le serveur accepte.
  static const int minWorkDaysDivisor = 1;
  static const int maxWorkDaysDivisor = 31;

  /// Les valeurs de la spec, tant que l'école n'a rien posé.
  static const PayrollSettings defaults = PayrollSettings(
    monthlyHoursDivisor: 173,
    overtimeMultiplierPermille: 1300,
    allowanceEligibleKinds: {
      StaffContractKind.permanent,
      StaffContractKind.vacataire,
      StaffContractKind.conventionne,
    },
    byCurrency: {
      CurrencyCode.usd: PayrollCurrencySettings(
        childAllowanceInCents: 500,
        defaultOvertimeRateInCents: 300,
        overtimeRateStepInCents: 50,
      ),
      CurrencyCode.cdf: PayrollCurrencySettings(
        childAllowanceInCents: 1400000,
        defaultOvertimeRateInCents: 850000,
        overtimeRateStepInCents: 50000,
      ),
    },
  );

  /// La première devise réglée : celle d'une ligne qui n'en porte aucune
  /// (conventionné sans prime).
  String get firstCurrency =>
      byCurrency.isEmpty ? CurrencyCode.usd : byCurrency.keys.first;

  PayrollCurrencySettings of(String currency) =>
      byCurrency[CurrencyCode.normalize(currency)] ??
      PayrollCurrencySettings.none;

  PayrollSettings copyWith({
    int? monthlyHoursDivisor,
    int? overtimeMultiplierPermille,
    Set<StaffContractKind>? allowanceEligibleKinds,
    Map<String, PayrollCurrencySettings>? byCurrency,
    int? workDaysDivisor,
    bool? absenceDeductionEnabled,
  }) => PayrollSettings(
    monthlyHoursDivisor: monthlyHoursDivisor ?? this.monthlyHoursDivisor,
    overtimeMultiplierPermille:
        overtimeMultiplierPermille ?? this.overtimeMultiplierPermille,
    allowanceEligibleKinds:
        allowanceEligibleKinds ?? this.allowanceEligibleKinds,
    byCurrency: byCurrency ?? this.byCurrency,
    workDaysDivisor: workDaysDivisor ?? this.workDaysDivisor,
    absenceDeductionEnabled:
        absenceDeductionEnabled ?? this.absenceDeductionEnabled,
    syncState: syncState,
  );

  @override
  List<Object?> get props => [
    monthlyHoursDivisor,
    overtimeMultiplierPermille,
    allowanceEligibleKinds,
    byCurrency,
    workDaysDivisor,
    absenceDeductionEnabled,
    syncState,
  ];
}
