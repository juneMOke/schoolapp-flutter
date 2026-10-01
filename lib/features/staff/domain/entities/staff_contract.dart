import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_period.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Une période de contrat **avec** ses montants — lisible seulement sous
/// `hr.pay.read`. Fait figé : jamais réécrite ; une période fausse est
/// corrigée par un remplaçant et reste pour l'historique.
class StaffContract extends Equatable {
  final String id;
  final String staffMemberId;
  final StaffContractKind? kind;
  final StaffPayMode? payMode;

  /// Jours `YYYY-MM-DD`.
  final String effectiveFrom;
  final String? endsOn;

  /// Salaire mensuel (permanent), taux horaire ou forfait (vacataire) ;
  /// `null` pour un conventionné.
  final Money? amount;
  final String? secopeNumber;

  /// Prime locale d'un conventionné, facultative.
  final Money? bonus;
  final String recordedAt;

  /// Corrigée : hors calcul, gardée pour l'historique.
  final String? correctedAt;
  final String? correctedByName;
  final String? correctionReason;

  /// Une correction de cette période est écrite sur la tablette et pas encore
  /// accusée.
  final bool correctionPending;
  final RecordSyncState syncState;

  /// Pourquoi le serveur a refusé la pose, ou la dernière correction.
  final String? syncError;

  const StaffContract({
    required this.id,
    required this.staffMemberId,
    required this.kind,
    required this.effectiveFrom,
    required this.recordedAt,
    required this.syncState,
    this.payMode,
    this.endsOn,
    this.amount,
    this.secopeNumber,
    this.bonus,
    this.correctedAt,
    this.correctedByName,
    this.correctionReason,
    this.correctionPending = false,
    this.syncError,
  });

  bool get isCorrected => correctedAt != null || correctionPending;

  /// Cette période telle que la frise la montre : statut et dates, sans
  /// montant.
  StaffContractPeriod get asPeriod => StaffContractPeriod(
    contractId: id,
    kind: kind,
    payMode: payMode,
    effectiveFrom: effectiveFrom,
    endsOn: endsOn,
  );

  @override
  List<Object?> get props => [
    id,
    staffMemberId,
    kind,
    payMode,
    effectiveFrom,
    endsOn,
    amount,
    secopeNumber,
    bonus,
    recordedAt,
    correctedAt,
    correctedByName,
    correctionReason,
    correctionPending,
    syncState,
    syncError,
  ];
}
