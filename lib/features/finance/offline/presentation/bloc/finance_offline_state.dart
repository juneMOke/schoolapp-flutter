import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';

abstract class FinanceOfflineState extends Equatable {
  const FinanceOfflineState();

  @override
  List<Object?> get props => [];
}

class FinanceOfflineInitial extends FinanceOfflineState {
  const FinanceOfflineInitial();
}

class FinanceOfflineLoading extends FinanceOfflineState {
  const FinanceOfflineLoading();
}

class FinanceOfflineChargesLoaded extends FinanceOfflineState {
  final List<LocalStudentCharge> charges;

  const FinanceOfflineChargesLoaded(this.charges);

  @override
  List<Object?> get props => [charges];
}

class FinanceOfflinePaymentsLoaded extends FinanceOfflineState {
  final List<LocalPayment> payments;

  const FinanceOfflinePaymentsLoaded(this.payments);

  @override
  List<Object?> get props => [payments];
}

class FinanceOfflineRecording extends FinanceOfflineState {
  const FinanceOfflineRecording();
}

/// Paiement enregistré localement : en attente de synchro (solde optimiste mis
/// à jour, RC provisoire émis). État pending-sync exposé à l'UI.
class FinanceOfflinePaymentPendingSync extends FinanceOfflineState {
  final String paymentId;

  const FinanceOfflinePaymentPendingSync(this.paymentId);

  @override
  List<Object?> get props => [paymentId];
}

class FinanceOfflineError extends FinanceOfflineState {
  final String message;

  /// Refus attendu, pas une panne : une correction de niveau retient la caisse
  /// de l'élève (D7). L'écran le dit tel quel, sans code d'incident.
  final bool heldByLevelCorrection;

  const FinanceOfflineError(this.message, {this.heldByLevelCorrection = false});

  @override
  List<Object?> get props => [message, heldByLevelCorrection];
}
