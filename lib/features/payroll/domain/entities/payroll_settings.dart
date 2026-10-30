import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_currency_settings.dart';

export 'package:school_app_flutter/features/payroll/domain/entities/payroll_currency_settings.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Les réglages de paie d'une école. Entiers seulement : la majoration est en
/// pour mille, jamais un flottant qui arrondirait autrement en Java.
class PayrollSettings extends Equatable {
  /// Heures d'un mois plein, pour le taux horaire d'un permanent.
  final int monthlyHoursDivisor;

  /// 1300 = +30 %.
  final int overtimeMultiplierPermille;

  /// Les statuts qui ouvrent les allocations familiales de l'école.
  final Set<StaffContractKind> allowanceEligibleKinds;

  /// Déprécié depuis la formule 3 : le diviseur de l'absence est le nombre
  /// de jours ouvrés du mois (`PayrollWorkingDays`). Encore servi par le
  /// serveur, renvoyé tel quel, jamais lu par le moteur.
  final int workDaysDivisor;

  /// Coupée par défaut : une école qui ne règle rien est payée comme en v1.
  final bool absenceDeductionEnabled;

  /// Par code ISO.
  final Map<String, PayrollCurrencySettings> byCurrency;

  /// Q8 — charges patronales en ‰ (CNSS, INPP, ONEM) : le coût employeur de
  /// la tablette ; aucun calcul de paie ne les lit.
  final int cnssEmployerPermille;
  final int inppPermille;
  final int onemPermille;

  /// Q8 — plafond d'une échéance d'avance en % du salaire de base : un
  /// avertissement à la demande, jamais un refus.
  final int advanceMaxPercent;

  /// Q8 — échéances d'un prêt au plus, jugées par le serveur au dépôt.
  final int loanMaxMonths;

  /// Q8 — la PC/E est-elle retenue ? Coupée, le moteur la compte à 0, des
  /// deux côtés ; les montants saisis restent rangés.
  final bool childcareEnabled;

  /// Q8 — les intitulés de signature du bulletin ; `null` = ceux du modèle
  /// papier (Bénéficiaire · DG · Caissier(e)).
  final String? signatureBeneficiaryLabel;
  final String? signatureDirectorLabel;
  final String? signatureCashierLabel;

  /// Le serveur a-t-il servi les réglages Q8 ? Sinon, la tablette ne les
  /// montre pas et ne les remonte pas : leurs valeurs ci-dessus sont les
  /// défauts du serveur, qu'elle n'a pas à imposer.
  final bool wideSettingsServed;
  final RecordSyncState syncState;

  const PayrollSettings({
    required this.monthlyHoursDivisor,
    required this.overtimeMultiplierPermille,
    required this.allowanceEligibleKinds,
    required this.byCurrency,
    this.workDaysDivisor = defaultWorkDaysDivisor,
    this.absenceDeductionEnabled = false,
    this.cnssEmployerPermille = defaultCnssEmployerPermille,
    this.inppPermille = defaultInppPermille,
    this.onemPermille = defaultOnemPermille,
    this.advanceMaxPercent = defaultAdvanceMaxPercent,
    this.loanMaxMonths = defaultLoanMaxMonths,
    this.childcareEnabled = true,
    this.signatureBeneficiaryLabel,
    this.signatureDirectorLabel,
    this.signatureCashierLabel,
    this.wideSettingsServed = false,
    this.syncState = RecordSyncState.synced,
  });

  static const int defaultCnssEmployerPermille = 130;
  static const int defaultInppPermille = 20;
  static const int defaultOnemPermille = 2;
  static const int defaultAdvanceMaxPercent = 50;
  static const int defaultLoanMaxMonths = 4;

  /// Les charges patronales, en ‰ du brut.
  int get employerChargesPermille =>
      cnssEmployerPermille + inppPermille + onemPermille;

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
    int? cnssEmployerPermille,
    int? inppPermille,
    int? onemPermille,
    int? advanceMaxPercent,
    int? loanMaxMonths,
    bool? childcareEnabled,
    ({String? beneficiary, String? director, String? cashier})? signatures,
    RecordSyncState? syncState,
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
    cnssEmployerPermille: cnssEmployerPermille ?? this.cnssEmployerPermille,
    inppPermille: inppPermille ?? this.inppPermille,
    onemPermille: onemPermille ?? this.onemPermille,
    advanceMaxPercent: advanceMaxPercent ?? this.advanceMaxPercent,
    loanMaxMonths: loanMaxMonths ?? this.loanMaxMonths,
    childcareEnabled: childcareEnabled ?? this.childcareEnabled,
    // Les intitulés se posent ensemble : `null` dans le triplet = celui du
    // modèle papier.
    signatureBeneficiaryLabel: signatures == null
        ? signatureBeneficiaryLabel
        : signatures.beneficiary,
    signatureDirectorLabel: signatures == null
        ? signatureDirectorLabel
        : signatures.director,
    signatureCashierLabel: signatures == null
        ? signatureCashierLabel
        : signatures.cashier,
    wideSettingsServed: wideSettingsServed,
    syncState: syncState ?? this.syncState,
  );

  /// Les mêmes règles de calcul, quel que soit l'état d'envoi : un barème
  /// enregistré puis relu « en attente » n'est pas une modification.
  bool sameRulesAs(PayrollSettings other) =>
      copyWith(syncState: other.syncState) == other;

  @override
  List<Object?> get props => [
    monthlyHoursDivisor,
    overtimeMultiplierPermille,
    allowanceEligibleKinds,
    byCurrency,
    workDaysDivisor,
    absenceDeductionEnabled,
    cnssEmployerPermille,
    inppPermille,
    onemPermille,
    advanceMaxPercent,
    loanMaxMonths,
    childcareEnabled,
    signatureBeneficiaryLabel,
    signatureDirectorLabel,
    signatureCashierLabel,
    wideSettingsServed,
    syncState,
  ];
}
