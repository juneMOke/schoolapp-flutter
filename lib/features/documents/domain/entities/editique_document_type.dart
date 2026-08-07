/// Les pièces d'éditique que le front sait émettre.
///
/// Le bulletin (`BU`, `POST /academics/bulletins/emit`) est **hors périmètre** :
/// il exige `classroomId` + `periodeScolaireId`, qu'aucun endpoint branché côté
/// front ne permet d'obtenir depuis un élève, et son émission n'est pas
/// idempotente. Il reste émis par la clôture de période du module Résultats,
/// qui travaille au niveau classe — son niveau naturel.
enum EditiqueDocumentType {
  /// Attestation d'inscription — `POST /enrollments/{enrollmentId}/attestation`.
  enrollmentAttestation('AI'),

  /// Note de perception annuelle — `POST /finance/students/{studentId}/note-perception`.
  notePerception('NP'),

  /// Reçu d'un paiement — `POST /finance/payments/{paymentId}/receipt`.
  paymentReceipt('RC'),

  /// Relevé de compte horodaté — `POST /finance/students/{studentId}/releve`.
  accountStatement('RL'),

  /// Quitus financier horodaté — `POST /finance/students/{studentId}/quitus`.
  financialClearance('QT');

  /// Préfixe du numéro de pièce côté serveur (`ETL-AI-2526-000087`).
  final String code;

  const EditiqueDocumentType(this.code);

  /// Vrai si le serveur **archive** la pièce et re-sert les mêmes octets sous le
  /// même numéro à chaque appel.
  ///
  /// Faux pour [accountStatement] et [financialClearance] : le serveur les
  /// décrit comme « timestamped (not archived) » et consomme un numéro de
  /// séquence **avant** de rendre le PDF. Un second appel après un échec ne
  /// re-sert donc pas la même pièce — il en crée une nouvelle, numérotée, sans
  /// laisser de trace de la première.
  bool get isArchived =>
      this == enrollmentAttestation ||
      this == notePerception ||
      this == paymentReceipt;

  /// Vrai si un rejeu après échec est **sûr**.
  ///
  /// C'est le signal que la couche présentation devra lire pour décider
  /// d'offrir ou non « Réessayer » : sur une pièce non rejouable, un échec
  /// réseau ou un dépassement de délai est ambigu (le serveur a pu produire la
  /// pièce et brûler son numéro avant que la réponse n'arrive), et réessayer
  /// garantit un doublon numéroté.
  bool get isReplayable => isArchived;
}
