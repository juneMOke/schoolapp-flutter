import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

abstract class FinanceOfflineEvent extends Equatable {
  const FinanceOfflineEvent();

  @override
  List<Object?> get props => [];
}

/// Charge le grand-livre local (créances) d'un élève.
class LoadLocalCharges extends FinanceOfflineEvent {
  final String studentId;

  const LoadLocalCharges(this.studentId);

  @override
  List<Object?> get props => [studentId];
}

/// Charge l'historique de paiements local d'un élève.
class LoadLocalPayments extends FinanceOfflineEvent {
  final String studentId;

  const LoadLocalPayments(this.studentId);

  @override
  List<Object?> get props => [studentId];
}

/// Encaisse un paiement en local-first.
class RecordLocalPayment extends FinanceOfflineEvent {
  final RecordPaymentDraft draft;

  const RecordLocalPayment(this.draft);

  @override
  List<Object?> get props => [draft.hashCode];
}
