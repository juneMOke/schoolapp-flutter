import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_catalog_entry.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_generated_document.dart';

/// Ce que propose la ligne de document.
enum DocumentsCatalogActionKind {
  /// Pièce figée dont cette tablette n'a aucune trace → « Émettre ».
  emit,

  /// Pièce figée déjà scellée et connue localement → « Consulter ». Le serveur
  /// re-sert les mêmes octets sous le même numéro : rien n'est régénéré.
  consult,

  /// Pièce horodatée → « Générer maintenant », **après confirmation** : chaque
  /// appel consomme un numéro de séquence et n'archive rien.
  generate,

  /// Aucune action possible. Le motif est dans [DocumentsCatalogAction.reason].
  disabled,
}

/// Pourquoi la ligne est éteinte. Chaque motif a son message : une action
/// éteinte sans explication est un cul-de-sac.
enum DocumentsCatalogBlockReason {
  /// Rien n'est encore tranché (lecture locale en cours). On éteint **sans**
  /// rien annoncer : une raison qu'on ne connaît pas ne s'affiche pas.
  resolving,

  /// L'élève n'est pas encore connu du serveur — son uuid est client, l'appel
  /// répondrait 404. RG-012-1 : la demande est annoncée comme différée.
  pendingSync,

  /// Le dossier d'inscription n'est pas encore acquitté : son `enrollmentId`
  /// local ne veut rien dire pour le serveur.
  enrollmentPendingSync,

  /// Aucune référence de dossier — cas d'un lien profond rechargé, où `extra`
  /// est perdu. Seule l'attestation est concernée.
  missingEnrollmentRef,

  /// Le dossier n'a pas pu être lu en local (base illisible, dossier absent).
  /// Distinct de [resolving] : ici la lecture est TERMINÉE et n'a rien donné —
  /// on le dit, au lieu de laisser une action éteinte sans explication pour
  /// toujours.
  enrollmentUnreadable,

  /// Radio coupée (B-2) : l'émission est une opération serveur.
  offline,

  /// Le reçu se produit **par versement**, à l'encaissement, depuis la
  /// Facturation. Le catalogue le montre pour la complétude du dossier, mais ne
  /// l'émet pas : il n'a pas de versement à désigner.
  issuedFromBilling,
}

/// Issue de la matrice des actions (§10 de la spec), augmentée des gardes de
/// synchro que la spec ne prévoit pas — trois des quatre identifiants
/// nécessaires sont des uuid **client** avant l'acquittement serveur.
class DocumentsCatalogAction extends Equatable {
  final DocumentsCatalogActionKind kind;
  final DocumentsCatalogBlockReason? reason;

  /// Numéro et date de la pièce déjà scellée, quand cette tablette en a la
  /// trace. Alimente le sous-titre « Dernière émission … ».
  final LocalGeneratedDocument? knownPiece;

  /// Copie scellée détenue localement, quand il y en a une. C'est elle qui
  /// porte de quoi la ressortir — identifiant d'archive ou numéro — et sa
  /// présence est ce qui autorise « Consulter » hors ligne.
  final EditiqueCacheEntry? cachedPiece;

  const DocumentsCatalogAction._({
    required this.kind,
    this.reason,
    this.knownPiece,
    this.cachedPiece,
  });

  /// Vrai quand l'action ressort une copie locale au lieu de demander une
  /// production au serveur.
  bool get isRestitution => cachedPiece != null;

  bool get isEnabled => kind != DocumentsCatalogActionKind.disabled;

  /// Vrai quand l'émission consomme un numéro de séquence : elle exige alors
  /// une confirmation explicite.
  bool get needsConfirmation => kind == DocumentsCatalogActionKind.generate;

  /// Résout l'action d'une ligne.
  ///
  /// L'ordre des tests est celui du message qu'on veut donner : on nomme
  /// d'abord la cause la plus structurelle (« ce document ne s'émet pas ici »),
  /// puis les causes conjoncturelles (pas synchronisé, hors ligne).
  ///
  /// [isStudentKnownToServer] vaut `null` tant que la lecture locale n'a pas
  /// tranché — l'action reste éteinte et muette.
  factory DocumentsCatalogAction.resolve({
    required EditiqueCatalogEntry entry,
    required bool? isStudentKnownToServer,
    required bool isOffline,
    required String enrollmentId,
    required SyncState? enrollmentSyncState,
    required bool isDossierLoaded,
    required List<LocalGeneratedDocument> knownPieces,
    List<EditiqueCacheEntry> cachedPieces = const <EditiqueCacheEntry>[],
  }) {
    // Le reçu est le seul document par VERSEMENT : le catalogue, qui raisonne
    // par élève, n'a aucun versement à désigner.
    if (entry.type == EditiqueDocumentType.paymentReceipt) {
      return const DocumentsCatalogAction._(
        kind: DocumentsCatalogActionKind.disabled,
        reason: DocumentsCatalogBlockReason.issuedFromBilling,
      );
    }

    // L'attestation est la seule pièce clé-dossier ; les trois autres sont
    // clé-élève. Ses gardes sont donc distinctes.
    final isAttestation =
        entry.type == EditiqueDocumentType.enrollmentAttestation;

    if (isAttestation) {
      if (enrollmentId.trim().isEmpty) {
        return const DocumentsCatalogAction._(
          kind: DocumentsCatalogActionKind.disabled,
          reason: DocumentsCatalogBlockReason.missingEnrollmentRef,
        );
      }
      if (enrollmentSyncState == null) {
        return DocumentsCatalogAction._(
          kind: DocumentsCatalogActionKind.disabled,
          // Tant que la lecture court, on se tait ; une fois qu'elle a rendu
          // sans rien trouver, on l'explique. Sans cette distinction, une base
          // illisible laissait la ligne éteinte ET muette indéfiniment.
          reason: isDossierLoaded
              ? DocumentsCatalogBlockReason.enrollmentUnreadable
              : DocumentsCatalogBlockReason.resolving,
        );
      }
      if (!enrollmentSyncState.isSynced) {
        return const DocumentsCatalogAction._(
          kind: DocumentsCatalogActionKind.disabled,
          reason: DocumentsCatalogBlockReason.enrollmentPendingSync,
        );
      }
    } else {
      if (isStudentKnownToServer == null) {
        return const DocumentsCatalogAction._(
          kind: DocumentsCatalogActionKind.disabled,
          reason: DocumentsCatalogBlockReason.resolving,
        );
      }
      if (!isStudentKnownToServer) {
        return const DocumentsCatalogAction._(
          kind: DocumentsCatalogActionKind.disabled,
          reason: DocumentsCatalogBlockReason.pendingSync,
        );
      }
    }

    final known = _findDefinitive(knownPieces, entry.code);

    // Une pièce dont la tablette détient les OCTETS se consulte, en ligne comme
    // hors ligne : c'est une copie locale qu'on ressort, pas une production
    // qu'on demande au serveur. Cette porte s'ouvre donc AVANT la garde de
    // connectivité — sinon la restitution hors ligne, qui est l'objet même du
    // cache, resterait inatteignable.
    //
    // Elle s'ouvre sur un FAIT (une entrée d'index pour cette pièce), jamais
    // sur le barème : « restitution offline ✅ » dit ce que le type autorise,
    // pas ce qui est déjà là.
    final cached = _findCached(cachedPieces, entry.code);
    if (cached != null) {
      return DocumentsCatalogAction._(
        kind: DocumentsCatalogActionKind.consult,
        knownPiece: known,
        cachedPiece: cached,
      );
    }

    if (isOffline) {
      return const DocumentsCatalogAction._(
        kind: DocumentsCatalogActionKind.disabled,
        reason: DocumentsCatalogBlockReason.offline,
      );
    }

    if (!entry.isArchived) {
      return const DocumentsCatalogAction._(
        kind: DocumentsCatalogActionKind.generate,
      );
    }

    return DocumentsCatalogAction._(
      kind: known == null
          ? DocumentsCatalogActionKind.emit
          : DocumentsCatalogActionKind.consult,
      knownPiece: known,
    );
  }

  /// Copie scellée de ce type détenue par la tablette, la plus récemment émise
  /// d'abord — l'ordre que rend déjà l'index.
  ///
  /// Ne cherche que parmi les types **archivés** : le cache n'admet pas les
  /// autres, et une entrée qui y figurerait quand même ne doit pas devenir un
  /// bouton.
  static EditiqueCacheEntry? _findCached(
    List<EditiqueCacheEntry> cached,
    String code,
  ) {
    for (final entry in cached) {
      if (entry.docType.toUpperCase() == code.toUpperCase()) return entry;
    }
    return null;
  }

  /// Pièce **définitive** de ce type dont la tablette a la trace.
  ///
  /// Un `PROV-…` ne compte pas : il n'a pas de valeur probante et son numéro
  /// n'est pas celui que le serveur re-servira.
  static LocalGeneratedDocument? _findDefinitive(
    List<LocalGeneratedDocument> pieces,
    String code,
  ) {
    for (final piece in pieces) {
      if (piece.docType == code && piece.isDefinitive) return piece;
    }
    return null;
  }

  @override
  List<Object?> get props => [kind, reason, knownPiece, cachedPiece];
}
