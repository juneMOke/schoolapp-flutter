import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';

/// Émission des pièces d'éditique. Chaque appel est un aller-retour serveur :
/// aucune de ces opérations ne fonctionne hors ligne, et aucune ne passe par
/// l'outbox (une pièce n'est pas une mutation métier à rejouer plus tard — elle
/// doit être produite maintenant ou pas du tout).
abstract class EditiqueRepository {
  /// Attestation d'inscription (AI). Archivée et idempotente.
  Future<Either<Failure, EditiqueDocument>> emitEnrollmentAttestation({
    required String enrollmentId,
  });

  /// Note de perception annuelle (NP). Archivée et idempotente.
  Future<Either<Failure, EditiqueDocument>> emitNotePerception({
    required String studentId,
    required String academicYearId,
  });

  /// Reçu d'un paiement (RC). Archivé et idempotent.
  ///
  /// Le [paymentId] doit être un identifiant **connu du serveur** : un paiement
  /// encore en attente de synchro porte un uuid client, qui produira un 404.
  Future<Either<Failure, EditiqueDocument>> emitPaymentReceipt({
    required String paymentId,
  });

  /// Relevé de compte (RL). Horodaté, **non archivé** : chaque appel consomme un
  /// numéro de séquence côté serveur.
  Future<Either<Failure, EditiqueDocument>> emitAccountStatement({
    required String studentId,
    required String academicYearId,
  });

  /// Quitus financier (QT). Horodaté, **non archivé** : chaque appel consomme un
  /// numéro de séquence côté serveur.
  ///
  /// Le serveur émet la pièce même lorsque le solde n'est pas nul — elle porte
  /// alors la mention « NON EN RÈGLE ». Ce n'est donc pas une erreur à
  /// intercepter ici, mais un avertissement à porter dans l'UI.
  Future<Either<Failure, EditiqueDocument>> emitFinancialClearance({
    required String studentId,
    required String academicYearId,
  });
}
