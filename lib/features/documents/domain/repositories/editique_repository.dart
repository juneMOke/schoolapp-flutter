import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';

/// Les pièces d'éditique, et **deux verbes qu'il ne faut pas confondre**
/// (ADR-012 D-1).
///
/// **Émettre**, c'est demander au serveur de produire une pièce : un
/// aller-retour obligatoire, qui ne fonctionne pas hors ligne et qui ne passe
/// pas par l'outbox — une pièce n'est pas une mutation métier à rejouer plus
/// tard, elle est produite maintenant ou pas du tout. Sur un relevé ou un
/// quitus, l'appel consomme en outre un numéro de séquence.
///
/// **Restituer**, c'est ressortir une pièce déjà scellée : le cache local
/// d'abord, le re-téléchargement ensuite. Aucun numéro n'est consommé, rien
/// n'est produit, et l'opération se rejoue librement. Elle n'existe que pour
/// les pièces que le serveur **archive** — un relevé et un quitus sont
/// recalculés à chaque fois, il n'y a rien à restituer.
abstract class EditiqueRepository {
  /// Attestation d'inscription (AI). Archivée et idempotente.
  ///
  /// [studentId] et [academicYearId] ne servent **pas** à l'appel serveur, qui
  /// ne connaît que le dossier : ils attribuent la copie locale. Sans eux, la
  /// pièce est mise en cache sans élève, et la seule lecture qui alimente le
  /// catalogue — « les pièces de cet élève » — ne la retrouve jamais : les
  /// octets occupent le budget sans qu'aucun écran ne puisse les ressortir.
  Future<Either<Failure, EditiqueDocument>> emitEnrollmentAttestation({
    required String enrollmentId,
    String? studentId,
    String? academicYearId,
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
  ///
  /// [studentId] et [academicYearId] attribuent la copie locale, comme pour
  /// l'attestation : le serveur, lui, ne connaît que le versement.
  Future<Either<Failure, EditiqueDocument>> emitPaymentReceipt({
    required String paymentId,
    String? studentId,
    String? academicYearId,
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

  /// Ressort une pièce **archivée** déjà scellée, sans rien produire.
  ///
  /// Le cache local d'abord — c'est ce qui la rend disponible hors ligne — puis
  /// le re-téléchargement par identifiant, qui ressert les octets gelés à
  /// l'identique (RG-012-3). Une pièce servie depuis le cache est la **même**
  /// pièce, au bit près : elle ne porte aucune marque, aucun filigrane, aucun
  /// bandeau. En ajouter un affaiblirait la valeur probante d'un document
  /// scellé.
  ///
  /// Au moins un des deux identifiants doit être fourni. Le numéro seul suffit
  /// à interroger le cache mais ne permet aucun re-téléchargement : le serveur
  /// n'expose pas de recherche par numéro.
  ///
  /// Lève si [type] n'est pas archivé : demander la restitution d'un relevé ou
  /// d'un quitus est une faute d'appelant, pas un cas d'échec. Ces pièces sont
  /// recalculées à chaque demande, et une copie locale en serait l'unique
  /// exemplaire au monde.
  /// [studentId] et [academicYearId] attribuent la copie déposée par un
  /// re-téléchargement. Les omettre recréerait une entrée orpheline là où il y
  /// en avait une attribuée — une pièce qui disparaîtrait du catalogue pour
  /// avoir été relue une fois de trop.
  Future<Either<Failure, EditiqueDocument>> restitute({
    required EditiqueDocumentType type,
    String? documentId,
    String? documentNumber,
    String? studentId,
    String? academicYearId,
  });
}
