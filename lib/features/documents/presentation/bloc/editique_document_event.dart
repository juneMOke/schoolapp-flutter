part of 'editique_document_bloc.dart';

sealed class EditiqueDocumentEvent extends Equatable {
  const EditiqueDocumentEvent();

  @override
  List<Object?> get props => [];
}

/// Demande le reçu (RC) d'un paiement.
///
/// [paymentId] doit être un identifiant **connu du serveur**. Le serveur honore
/// l'uuid client au push, donc l'id local devient valide dès la synchro — mais
/// un paiement encore `isPendingSync` produirait un 404. C'est à l'appelant de
/// garder le déclencheur : le BLoC ne peut pas le savoir.
class EditiquePaymentReceiptRequested extends EditiqueDocumentEvent {
  final String paymentId;

  const EditiquePaymentReceiptRequested({required this.paymentId});

  @override
  List<Object?> get props => [paymentId];
}
