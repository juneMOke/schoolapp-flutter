import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/mobile_money_operator.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_cancellation.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Un salaire versé. Le montant est le net figé ; [validationGestureId] nomme
/// la validation sous laquelle l'argent est sorti.
class PayrollDisbursement extends Equatable {
  final String id;

  /// `YYYY-MM`.
  final String month;
  final String staffMemberId;
  final String validationGestureId;
  final Money amount;
  final PayoutMode mode;
  final MobileMoneyOperator? operator;
  final String? payoutPhone;
  final String? reference;
  final String? bankName;
  final String? bankAccount;
  final bool signedRegister;

  /// Instant UTC ISO-8601.
  final String paidAt;
  final String? authorName;
  final PayrollCancellation? cancellation;
  final RecordSyncState syncState;
  final String? syncError;
  final String? syncErrorCode;

  const PayrollDisbursement({
    required this.id,
    required this.month,
    required this.staffMemberId,
    required this.validationGestureId,
    required this.amount,
    required this.mode,
    required this.paidAt,
    this.operator,
    this.payoutPhone,
    this.reference,
    this.bankName,
    this.bankAccount,
    this.signedRegister = false,
    this.authorName,
    this.cancellation,
    this.syncState = RecordSyncState.synced,
    this.syncError,
    this.syncErrorCode,
  });

  /// Refusé : l'argent est parti, le serveur ne l'a pas enregistré. À
  /// régulariser, jamais effacé.
  bool get needsRegularization => syncState == RecordSyncState.failed;

  bool get isCancelled {
    final cancellation = this.cancellation;
    return cancellation != null && !cancellation.isRefused;
  }

  /// Compte comme « versé » : ni annulé, ni refusé.
  bool get isLive => !isCancelled && !needsRegularization;

  @override
  List<Object?> get props => [
    id,
    month,
    staffMemberId,
    validationGestureId,
    amount,
    mode,
    operator,
    payoutPhone,
    reference,
    bankName,
    bankAccount,
    signedRegister,
    paidAt,
    authorName,
    cancellation,
    syncState,
    syncError,
    syncErrorCode,
  ];
}
