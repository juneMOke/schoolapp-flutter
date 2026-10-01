import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Les réglages d'une devise : allocation par enfant, taux d'heure sup. par
/// défaut, et le pas auquel s'arrondit un taux calculé. Centimes.
class PayrollCurrencySettings extends Equatable {
  final int childAllowanceInCents;
  final int defaultOvertimeRateInCents;
  final int overtimeRateStepInCents;

  const PayrollCurrencySettings({
    required this.childAllowanceInCents,
    required this.defaultOvertimeRateInCents,
    required this.overtimeRateStepInCents,
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

  /// Par code ISO.
  final Map<String, PayrollCurrencySettings> byCurrency;
  final RecordSyncState syncState;

  const PayrollSettings({
    required this.monthlyHoursDivisor,
    required this.overtimeMultiplierPermille,
    required this.allowanceEligibleKinds,
    required this.byCurrency,
    this.syncState = RecordSyncState.synced,
  });

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
  }) => PayrollSettings(
    monthlyHoursDivisor: monthlyHoursDivisor ?? this.monthlyHoursDivisor,
    overtimeMultiplierPermille:
        overtimeMultiplierPermille ?? this.overtimeMultiplierPermille,
    allowanceEligibleKinds:
        allowanceEligibleKinds ?? this.allowanceEligibleKinds,
    byCurrency: byCurrency ?? this.byCurrency,
    syncState: syncState,
  );

  @override
  List<Object?> get props => [
    monthlyHoursDivisor,
    overtimeMultiplierPermille,
    allowanceEligibleKinds,
    byCurrency,
    syncState,
  ];
}
