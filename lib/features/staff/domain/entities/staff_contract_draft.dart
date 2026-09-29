import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Un contrat en cours de saisie — une pose (« Nouveau contrat à compter
/// du… ») ou le remplaçant d'une correction. Les montants sont gardés tels
/// que tapés : la validation les lit, le dépôt les convertit.
class StaffContractDraft extends Equatable {
  final StaffContractKind? kind;
  final StaffPayMode? payMode;
  final String? effectiveFrom;
  final String? endsOn;
  final String amount;
  final String currency;
  final String secopeNumber;
  final String bonus;
  final String bonusCurrency;

  /// Ce qui était faux (correction seulement).
  final String reason;

  const StaffContractDraft({
    this.kind,
    this.payMode,
    this.effectiveFrom,
    this.endsOn,
    this.amount = '',
    this.currency = CurrencyCode.usd,
    this.secopeNumber = '',
    this.bonus = '',
    this.bonusCurrency = CurrencyCode.usd,
    this.reason = '',
  });

  /// Le remplaçant d'une période, prérempli avec ce qu'elle disait.
  factory StaffContractDraft.of(
    StaffContract contract, {
    required String Function(int cents) amountText,
  }) => StaffContractDraft(
    kind: contract.kind,
    payMode: contract.payMode,
    effectiveFrom: contract.effectiveFrom,
    endsOn: contract.endsOn,
    amount: contract.amount == null
        ? ''
        : amountText(contract.amount!.amountInCents),
    currency: contract.amount?.currency ?? CurrencyCode.usd,
    secopeNumber: contract.secopeNumber ?? '',
    bonus: contract.bonus == null
        ? ''
        : amountText(contract.bonus!.amountInCents),
    bonusCurrency: contract.bonus?.currency ?? CurrencyCode.usd,
  );

  bool get isVacataire => kind == StaffContractKind.vacataire;
  bool get isConventionne => kind == StaffContractKind.conventionne;

  /// Un salaire, un taux ou un forfait est exigé — pas pour un conventionné.
  bool get needsAmount => kind != null && !isConventionne;

  StaffContractDraft copyWith({
    StaffContractKind? Function()? kind,
    StaffPayMode? Function()? payMode,
    String? Function()? effectiveFrom,
    String? Function()? endsOn,
    String? amount,
    String? currency,
    String? secopeNumber,
    String? bonus,
    String? bonusCurrency,
    String? reason,
  }) => StaffContractDraft(
    kind: kind == null ? this.kind : kind(),
    payMode: payMode == null ? this.payMode : payMode(),
    effectiveFrom: effectiveFrom == null ? this.effectiveFrom : effectiveFrom(),
    endsOn: endsOn == null ? this.endsOn : endsOn(),
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    secopeNumber: secopeNumber ?? this.secopeNumber,
    bonus: bonus ?? this.bonus,
    bonusCurrency: bonusCurrency ?? this.bonusCurrency,
    reason: reason ?? this.reason,
  );

  @override
  List<Object?> get props => [
    kind,
    payMode,
    effectiveFrom,
    endsOn,
    amount,
    currency,
    secopeNumber,
    bonus,
    bonusCurrency,
    reason,
  ];
}
