import 'package:equatable/equatable.dart';

/// Une pièce scellée présente dans le cache de restitution — **ses métadonnées
/// seules** (ADR-012 D-2, AM-10).
///
/// Les octets ne sont pas ici et ne le seront jamais : ils vivent dans un
/// fichier chiffré hors base, dont le nom se dérive de [id]. Cette classe est
/// donc l'entrée d'index qui permet de retrouver ce fichier, d'en vérifier
/// l'intégrité ([contentSha256]) et d'en mesurer le poids ([sizeBytes]) sans
/// jamais l'ouvrir.
class EditiqueCacheEntry extends Equatable {
  /// Types de pièces **archivées** par le serveur, et donc les seuls que le
  /// cache admette.
  ///
  /// Distinct — à dessein — de `EditiqueDocumentType`, qui décrit ce que le
  /// front sait **émettre**. Les deux ensembles divergent dans les deux sens :
  ///
  /// - `RL` (relevé) et `QT` (quitus) s'émettent mais ne s'archivent pas. Le
  ///   serveur les décrit « timestamped (not archived) » : une copie locale
  ///   serait l'unique exemplaire au monde, et l'éviction LRU la détruirait.
  ///   Les admettre retirerait au cache la propriété qui rend l'éviction
  ///   acceptable — « une pièce évincée reste re-téléchargeable » ;
  /// - `BU` (bulletin) s'archive mais ne s'émet pas depuis le front : il est
  ///   scellé en ligne par la clôture de période, côté serveur, et n'atteindra
  ///   ce cache que par le pull des métadonnées (lot L3.4).
  ///
  /// La contrainte est **doublée en SQL** (`CHECK`) : c'est un invariant de
  /// stockage, pas une politique d'appelant.
  static const Set<String> cacheableDocTypes = {'AI', 'NP', 'RC', 'BU'};

  /// Clé locale, stable pour la vie de l'entrée. C'est elle qui nomme le
  /// fichier chiffré — jamais le numéro de pièce, qui exposerait le type et le
  /// rang du document en clair dans un listing de répertoire.
  final String id;

  /// Identifiant serveur de la pièce, `null` tant que l'émission ne le rend pas
  /// (rupture back R2 : seul le reçu en porte un, via `payment.receiptId`).
  final String? documentId;

  /// Numéro de pièce (`ETL-RC-2526-000212`), unique par école. Lu best-effort
  /// dans le `filename` du `Content-Disposition`, en-tête non contractualisé :
  /// il peut manquer, d'où sa nullabilité.
  final String? documentNumber;

  /// Code serveur du type de pièce, restreint à [cacheableDocTypes].
  final String docType;

  final String? studentId;

  /// Année de la pièce. Clé de **scope et de mesure**, jamais de purge
  /// automatique (AM-8 : la purge calendaire est supprimée).
  final String? academicYearId;

  /// École propriétaire. Portée de lecture, et périmètre d'effacement physique
  /// à la réaffectation de la tablette (D-7).
  final String schoolId;

  /// Compte à l'origine de la mise en cache. **Provenance**, pas cloisonnement :
  /// une pièce est un document d'établissement, deux agents du même guichet
  /// partagent la même copie.
  final String ownerUid;

  /// Poids des octets scellés (le clair, avant chiffrement de stockage). Le
  /// surcoût du chiffrement au repos est borné et constant — nonce + tag
  /// AES-GCM, quelques dizaines d'octets par fichier — donc négligeable devant
  /// un budget exprimé en gigaoctets.
  final int sizeBytes;

  /// Empreinte des octets scellés, ou `null` quand la tablette **n'a pas** les
  /// octets — elle sait seulement que la pièce existe, l'ayant apprise par le
  /// delta de synchronisation.
  ///
  /// C'est la seule chose qui distingue les deux natures de ligne, et tout en
  /// dépend : une ligne sans empreinte ne pèse pas au budget, ne s'évince pas,
  /// et une lecture qui tombe dessus ne la supprime pas — la connaissance
  /// survit, seuls les octets manquent.
  final String? contentSha256;

  /// Époch ms de l'émission côté serveur, `null` si elle n'est pas connue —
  /// seul le listing serveur la rend. C'est elle, et non [createdAt], qui
  /// ordonne une liste de pièces : un bulletin de juin descendu par la synchro
  /// de septembre n'est pas la pièce la plus récente de l'élève.
  final int? emittedAt;

  /// Époch ms auquel le serveur a **retiré** la pièce, `null` tant qu'elle est
  /// en vigueur (lot back B5).
  ///
  /// Axe **orthogonal** à [contentSha256], et les confondre serait une faute :
  /// « retirée » et « pas d'octets ici » sont deux questions différentes, qui se
  /// croisent librement. Une pièce annulée garde d'ailleurs ses octets — un
  /// guichet doit pouvoir ressortir le papier qu'une famille lui présente pour
  /// lui expliquer pourquoi il n'a plus cours.
  final int? cancelledAt;

  /// Motif du retrait, tel que le serveur le descend.
  ///
  /// **Texte libre saisi par un agent** de l'école : il ne se traduit pas, ne se
  /// reformule pas, et s'affiche comme un détail serveur — jamais comme une
  /// phrase de l'application. Peut manquer alors même que [cancelledAt] est
  /// renseigné : le front reçoit ici une donnée qu'il ne contrôle pas.
  final String? cancellationReason;

  /// Époch ms de la mise en cache.
  final int createdAt;

  /// Époch ms du dernier accès. **Seule** entrée du classement LRU.
  final int lastAccessedAt;

  const EditiqueCacheEntry({
    required this.id,
    this.documentId,
    this.documentNumber,
    required this.docType,
    this.studentId,
    this.academicYearId,
    required this.schoolId,
    this.ownerUid = '',
    required this.sizeBytes,
    this.contentSha256,
    this.emittedAt,
    this.cancelledAt,
    this.cancellationReason,
    required this.createdAt,
    required this.lastAccessedAt,
  });

  /// Vrai si le type est archivé côté serveur, donc re-téléchargeable après
  /// éviction.
  static bool isCacheableDocType(String? docType) =>
      docType != null && cacheableDocTypes.contains(docType.toUpperCase());

  /// Vrai quand la tablette détient réellement les octets de cette pièce.
  ///
  /// Affirmation positive, jamais déduite d'une négation : « pas de
  /// connaissance » et « connaissance sans octets » ne doivent pas se
  /// confondre.
  bool get hasBytes => contentSha256 != null && contentSha256!.isNotEmpty;

  /// Vrai quand le serveur a retiré cette pièce.
  ///
  /// Affirmation positive, comme [hasBytes], et surtout **jamais** déduite de
  /// `!hasBytes` : une ligne sans octets est le cas ORDINAIRE d'une pièce
  /// apprise par le delta, et la lire « annulée » barrerait tout le catalogue.
  ///
  /// Se lit sur la seule date : le motif peut manquer sur une pièce pourtant
  /// bien retirée.
  bool get isCancelled => cancelledAt != null;

  /// Vrai si l'entrée porte de quoi être retrouvée. Une entrée sans aucun des
  /// deux identifiants est irrécupérable : son fichier occuperait le budget
  /// sans qu'aucune demande ne puisse jamais le désigner.
  bool get isAddressable =>
      (documentId?.isNotEmpty ?? false) ||
      (documentNumber?.isNotEmpty ?? false);

  Map<String, Object?> toMap() => {
    'id': id,
    'document_id': documentId,
    'document_number': documentNumber,
    'doc_type': docType,
    'student_id': studentId,
    'academic_year_id': academicYearId,
    'school_id': schoolId,
    'owner_uid': ownerUid,
    'size_bytes': sizeBytes,
    'content_sha256': contentSha256,
    'emitted_at': emittedAt,
    'cancelled_at': cancelledAt,
    'cancellation_reason': cancellationReason,
    'created_at': createdAt,
    'last_accessed_at': lastAccessedAt,
  };

  factory EditiqueCacheEntry.fromMap(Map<String, Object?> map) =>
      EditiqueCacheEntry(
        id: (map['id'] as String?) ?? '',
        documentId: map['document_id'] as String?,
        documentNumber: map['document_number'] as String?,
        docType: (map['doc_type'] as String?) ?? '',
        studentId: map['student_id'] as String?,
        academicYearId: map['academic_year_id'] as String?,
        schoolId: (map['school_id'] as String?) ?? '',
        ownerUid: (map['owner_uid'] as String?) ?? '',
        sizeBytes: (map['size_bytes'] as int?) ?? 0,
        contentSha256: map['content_sha256'] as String?,
        emittedAt: map['emitted_at'] as int?,
        cancelledAt: map['cancelled_at'] as int?,
        cancellationReason: map['cancellation_reason'] as String?,
        createdAt: (map['created_at'] as int?) ?? 0,
        lastAccessedAt: (map['last_accessed_at'] as int?) ?? 0,
      );

  @override
  List<Object?> get props => [
    id,
    documentId,
    documentNumber,
    docType,
    studentId,
    academicYearId,
    schoolId,
    ownerUid,
    sizeBytes,
    contentSha256,
    emittedAt,
    // Sans ces deux-là, les états qui portent une entrée — le dossier local, le
    // reçu de la Facturation — n'émettraient aucun rebuild le jour où une pièce
    // devient annulée : l'égalité de valeur les déclarerait identiques.
    cancelledAt,
    cancellationReason,
    createdAt,
    lastAccessedAt,
  ];
}
