import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_cancellation.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Une avance sur salaire, remboursée en 1 à 4 échéances retenues sur la paie,
/// à partir de [firstMonth], dans la devise du contrat.
class SalaryAdvance extends Equatable {
  final String id;
  final String staffMemberId;
  final Money amount;
  final int installments;

  /// `YYYY-MM`.
  final String firstMonth;
  final SalaryAdvanceReason reason;
  final String? reasonDetail;
  final PayoutMode mode;

  /// `YYYY-MM-DD`.
  final String grantedOn;

  /// Ce que le serveur a déjà retenu sur des mois validés, et ce qui reste ;
  /// lus par le registre seulement.
  final int deductedInCents;
  final int? balanceInCents;
  final PayrollCancellation? cancellation;
  final StaffSyncState syncState;
  final String? syncError;
  final String? syncErrorCode;

  const SalaryAdvance({
    required this.id,
    required this.staffMemberId,
    required this.amount,
    required this.installments,
    required this.firstMonth,
    required this.reason,
    required this.mode,
    required this.grantedOn,
    this.reasonDetail,
    this.deductedInCents = 0,
    this.balanceInCents,
    this.cancellation,
    this.syncState = StaffSyncState.synced,
    this.syncError,
    this.syncErrorCode,
  });

  /// Refusée par le serveur : elle n'existe pas pour lui — mais l'argent est
  /// sorti, elle reste listée à régulariser.
  bool get isRefused => syncState == StaffSyncState.failed;

  /// Annulée, ou en cours d'annulation sur cette tablette.
  bool get isCancelled {
    final cancellation = this.cancellation;
    return cancellation != null && !cancellation.isRefused;
  }

  /// Compte dans le calcul : ni refusée, ni annulée.
  bool get isLive => !isRefused && !isCancelled;

  /// Le reste à rembourser : celui du serveur, sinon le montant entier.
  int get remainingInCents =>
      balanceInCents ?? (amount.amountInCents - deductedInCents);

  bool get isSettled => isLive && remainingInCents <= 0;

  /// Vivante et pas encore soldée : ce que le registre dit « en cours ».
  bool get isOngoing => isLive && !isSettled;

  @override
  List<Object?> get props => [
    id,
    staffMemberId,
    amount,
    installments,
    firstMonth,
    reason,
    reasonDetail,
    mode,
    grantedOn,
    deductedInCents,
    balanceInCents,
    cancellation,
    syncState,
    syncError,
    syncErrorCode,
  ];
}
