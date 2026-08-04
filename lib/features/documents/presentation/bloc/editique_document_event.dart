part of 'editique_document_bloc.dart';

sealed class EditiqueDocumentEvent extends Equatable {
  const EditiqueDocumentEvent();

  @override
  List<Object?> get props => [];
}

/// Demande l'attestation d'inscription (AI) d'un dossier.
///
/// Pièce archivée et idempotente : le serveur re-sert les mêmes octets sous le
/// même numéro. [enrollmentId] doit être un identifiant **connu du serveur** —
/// un dossier encore local produirait un 404, et un candidat de réinscription
/// n'a aucun `enrollmentId` du tout (chaîne vide).
class EditiqueEnrollmentAttestationRequested extends EditiqueDocumentEvent {
  final String enrollmentId;

  const EditiqueEnrollmentAttestationRequested({required this.enrollmentId});

  @override
  List<Object?> get props => [enrollmentId];
}

/// Demande la note de perception annuelle (NP) d'un élève.
///
/// Pièce archivée et idempotente. Le serveur répond 404 quand l'élève n'a
/// aucune charge sur l'année, 422 quand ses charges mêlent plusieurs devises.
class EditiqueNotePerceptionRequested extends EditiqueDocumentEvent {
  final String studentId;
  final String academicYearId;

  const EditiqueNotePerceptionRequested({
    required this.studentId,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [studentId, academicYearId];
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

/// Demande le relevé de compte (RL) d'un élève sur une année.
///
/// ⚠️ **Non idempotent.** Le serveur horodate la pièce, ne l'archive jamais, et
/// consomme un numéro de séquence à chaque appel. L'appelant doit donc avoir
/// obtenu une confirmation explicite avant de poster cet événement — deux
/// envois produisent deux pièces numérotées distinctes pour le même élève.
class EditiqueAccountStatementRequested extends EditiqueDocumentEvent {
  final String studentId;
  final String academicYearId;

  const EditiqueAccountStatementRequested({
    required this.studentId,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [studentId, academicYearId];
}

/// Demande le quitus financier (QT) d'un élève sur une année.
///
/// ⚠️ **Non idempotent**, exactement comme le relevé : numéro de séquence
/// consommé à chaque appel, pièce jamais archivée, confirmation explicite exigée
/// de l'appelant.
///
/// Le serveur émet la pièce **quel que soit le solde** : un élève qui n'est pas
/// en règle reçoit un quitus portant la mention « NON EN RÈGLE ». Ce n'est pas
/// une erreur à intercepter, c'est un avertissement à porter **avant** l'appel.
class EditiqueFinancialClearanceRequested extends EditiqueDocumentEvent {
  final String studentId;
  final String academicYearId;

  const EditiqueFinancialClearanceRequested({
    required this.studentId,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [studentId, academicYearId];
}
