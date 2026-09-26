import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_status.dart';

/// Ce que l'écran doit savoir de la dernière correction qui vise un
/// versement : où elle en est, pourquoi, et ce qui la remplace.
class PaymentCorrectionSummary extends Equatable {
  final PaymentCorrectionStatus status;
  final String reasonCode;
  final String? reason;
  final String? replacementPaymentId;

  /// Le code du refus serveur, quand il y en a un.
  final String? errorCode;

  const PaymentCorrectionSummary({
    required this.status,
    required this.reasonCode,
    this.reason,
    this.replacementPaymentId,
    this.errorCode,
  });

  bool get isPending => status == PaymentCorrectionStatus.pending;

  bool get isRejected => status == PaymentCorrectionStatus.rejected;

  /// Le versement visé ne compte plus dans les soldes.
  bool get removesPayment => status.removesOrigin;

  @override
  List<Object?> get props => [
    status,
    reasonCode,
    reason,
    replacementPaymentId,
    errorCode,
  ];
}
