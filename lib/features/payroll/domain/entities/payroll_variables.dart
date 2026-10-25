import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Les éléments variables d'un agent pour un mois. `null` = la règle : zéro
/// heure sup., le taux du moteur, les enfants du profil ; en v2, les jours
/// prestés pré-remplis par le Pointage, aucune prise en charge, le taux du
/// mois.
class PayrollVariables extends Equatable {
  final String staffMemberId;
  final int? overtimeMinutes;
  final int? overtimeRateInCents;
  final int? dependentChildren;

  /// NJP — jours prestés, corrigés par l'économe ; `null` = pré-rempli.
  final int? workedDays;

  /// PC/E — prise en charge des enfants du personnel, montant du mois.
  final int? childcareInCents;

  /// Montant fixe versé ce mois, qui prime sur le taux du mois ; motif requis.
  final int? fixedPayoutInCents;
  final String? fixedPayoutReason;
  final RecordSyncState syncState;
  final String? syncError;

  const PayrollVariables({
    required this.staffMemberId,
    this.overtimeMinutes,
    this.overtimeRateInCents,
    this.dependentChildren,
    this.workedDays,
    this.childcareInCents,
    this.fixedPayoutInCents,
    this.fixedPayoutReason,
    this.syncState = RecordSyncState.synced,
    this.syncError,
  });

  @override
  List<Object?> get props => [
    staffMemberId,
    overtimeMinutes,
    overtimeRateInCents,
    dependentChildren,
    workedDays,
    childcareInCents,
    fixedPayoutInCents,
    fixedPayoutReason,
    syncState,
    syncError,
  ];
}
