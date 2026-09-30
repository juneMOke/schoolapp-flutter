import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Les éléments variables d'un agent pour un mois. `null` = la règle : zéro
/// heure sup., le taux du moteur, les enfants du profil.
class PayrollVariables extends Equatable {
  final String staffMemberId;
  final int? overtimeMinutes;
  final int? overtimeRateInCents;
  final int? dependentChildren;
  final StaffSyncState syncState;
  final String? syncError;

  const PayrollVariables({
    required this.staffMemberId,
    this.overtimeMinutes,
    this.overtimeRateInCents,
    this.dependentChildren,
    this.syncState = StaffSyncState.synced,
    this.syncError,
  });

  @override
  List<Object?> get props => [
    staffMemberId,
    overtimeMinutes,
    overtimeRateInCents,
    dependentChildren,
    syncState,
    syncError,
  ];
}
