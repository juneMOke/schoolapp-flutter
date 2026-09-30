import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/mobile_money_operator.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Le profil de paie d'un agent : ce qui préremplit ses éléments variables et
/// son versement. Donnée de paie, pas de la fiche.
class StaffPayProfile extends Equatable {
  final String staffMemberId;
  final int dependentChildren;
  final PayoutMode? preferredMode;
  final MobileMoneyOperator? operator;

  /// E.164, `+243…`.
  final String? payoutPhone;
  final String? bankName;
  final String? bankAccount;
  final StaffSyncState syncState;
  final String? syncError;

  const StaffPayProfile({
    required this.staffMemberId,
    this.dependentChildren = 0,
    this.preferredMode,
    this.operator,
    this.payoutPhone,
    this.bankName,
    this.bankAccount,
    this.syncState = StaffSyncState.synced,
    this.syncError,
  });

  /// Un agent sans profil : aucun enfant, aucun mode préféré.
  factory StaffPayProfile.empty(String staffMemberId) =>
      StaffPayProfile(staffMemberId: staffMemberId);

  @override
  List<Object?> get props => [
    staffMemberId,
    dependentChildren,
    preferredMode,
    operator,
    payoutPhone,
    bankName,
    bankAccount,
    syncState,
    syncError,
  ];
}
