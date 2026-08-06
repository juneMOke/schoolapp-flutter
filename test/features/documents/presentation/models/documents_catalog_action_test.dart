import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_catalog_entry.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';
import 'package:school_app_flutter/features/documents/presentation/models/documents_catalog_action.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_generated_document.dart';

EditiqueCatalogEntry _entry(EditiqueDocumentType type) =>
    EditiqueCatalogEntry.all.firstWhere((e) => e.type == type);

DocumentsCatalogAction _resolve(
  EditiqueDocumentType type, {
  bool? studentKnown = true,
  bool isOffline = false,
  String enrollmentId = 'e-1',
  SyncState? enrollmentSyncState = SyncState.synced,
  bool isDossierLoaded = true,
  List<LocalGeneratedDocument> knownPieces = const <LocalGeneratedDocument>[],
  List<EditiqueCacheEntry> cachedPieces = const <EditiqueCacheEntry>[],
}) => DocumentsCatalogAction.resolve(
  entry: _entry(type),
  isStudentKnownToServer: studentKnown,
  isOffline: isOffline,
  enrollmentId: enrollmentId,
  enrollmentSyncState: enrollmentSyncState,
  isDossierLoaded: isDossierLoaded,
  knownPieces: knownPieces,
  cachedPieces: cachedPieces,
);

/// Copie scellée détenue par la tablette.
EditiqueCacheEntry _cached({
  required String docType,
  String id = 'c-1',
  String documentId = 'doc-cache-1',
  String documentNumber = 'ETL-AI-2526-000431',
  String? contentSha256 = 'abc',
  int? cancelledAt,
  String? cancellationReason,
}) => EditiqueCacheEntry(
  id: id,
  documentId: documentId,
  documentNumber: documentNumber,
  docType: docType,
  schoolId: 'school-1',
  sizeBytes: 1024,
  contentSha256: contentSha256,
  cancelledAt: cancelledAt,
  cancellationReason: cancellationReason,
  createdAt: 1000,
  lastAccessedAt: 1000,
);

LocalGeneratedDocument _piece({
  required String docType,
  String status = 'DEFINITIVE',
  String number = 'ETL-AI-2526-000431',
  int createdAt = 1000,
}) => LocalGeneratedDocument(
  id: 'doc-1',
  docDomain: 'ENROLLMENT',
  docType: docType,
  number: number,
  status: status,
  createdAt: createdAt,
);

void main() {
  // L3.5 — ce que la tablette détient réellement, par opposition à ce que le
  // barème autorise.
  group('copie locale', () {
    // C'est l'objet même du cache : hors ligne, une pièce dont on a les octets
    // se consulte. La garde de connectivité ne doit donc PAS la précéder.
    test('se consulte hors ligne', () {
      final action = _resolve(
        EditiqueDocumentType.enrollmentAttestation,
        isOffline: true,
        cachedPieces: [_cached(docType: 'AI')],
      );

      expect(action.kind, DocumentsCatalogActionKind.consult);
      expect(action.isRestitution, isTrue);
      expect(action.cachedPiece?.documentId, 'doc-cache-1');
    });

    // Sans copie, la ligne retombe sur la règle d'avant : produire une pièce
    // reste une opération serveur.
    test('sans copie, le hors-ligne éteint la ligne', () {
      final action = _resolve(
        EditiqueDocumentType.enrollmentAttestation,
        isOffline: true,
      );

      expect(action.kind, DocumentsCatalogActionKind.disabled);
      expect(action.reason, DocumentsCatalogBlockReason.offline);
      expect(action.isRestitution, isFalse);
    });

    // La note de perception n'a AUCUN écrivain dans `generated_documents` :
    // sans le cache, sa ligne dirait « Émettre » à perpétuité.
    test('ouvre « Consulter » sur une pièce que la trace locale ignore', () {
      final action = _resolve(
        EditiqueDocumentType.notePerception,
        cachedPieces: [_cached(docType: 'NP')],
      );

      expect(action.kind, DocumentsCatalogActionKind.consult);
      expect(action.cachedPiece, isNotNull);
    });

    // La copie d'un autre type ne dit rien de celle-ci.
    test('ne confond pas les types', () {
      final action = _resolve(
        EditiqueDocumentType.notePerception,
        isOffline: true,
        cachedPieces: [_cached(docType: 'AI')],
      );

      expect(action.kind, DocumentsCatalogActionKind.disabled);
      expect(action.reason, DocumentsCatalogBlockReason.offline);
    });

    // Les gardes structurelles priment toujours : un dossier non acquitté n'a
    // rien pu produire, et le reçu ne s'émet pas depuis le catalogue.
    test('ne contourne pas les gardes de synchro', () {
      final action = _resolve(
        EditiqueDocumentType.enrollmentAttestation,
        enrollmentSyncState: SyncState.pendingSync,
        cachedPieces: [_cached(docType: 'AI')],
      );

      expect(action.kind, DocumentsCatalogActionKind.disabled);
      expect(action.reason, DocumentsCatalogBlockReason.enrollmentPendingSync);
    });

    test('ne rouvre pas la ligne du reçu', () {
      final action = _resolve(
        EditiqueDocumentType.paymentReceipt,
        cachedPieces: [_cached(docType: 'RC')],
      );

      expect(action.reason, DocumentsCatalogBlockReason.issuedFromBilling);
    });

    // Le sous-titre « Dernière émission » vient de la trace locale ; la copie
    // vient du cache. Les deux coexistent sans se remplacer.
    test('garde la trace locale à côté de la copie', () {
      final action = _resolve(
        EditiqueDocumentType.enrollmentAttestation,
        knownPieces: [_piece(docType: 'AI')],
        cachedPieces: [_cached(docType: 'AI')],
      );

      expect(action.kind, DocumentsCatalogActionKind.consult);
      expect(action.knownPiece, isNotNull);
      expect(action.cachedPiece, isNotNull);
    });
  });

  group('matrice des actions', () {
    // Le reçu est le seul document PAR VERSEMENT : le catalogue raisonne par
    // élève et n'a aucun versement à désigner.
    test('le reçu est toujours éteint et renvoie vers la Facturation', () {
      final action = _resolve(EditiqueDocumentType.paymentReceipt);

      expect(action.kind, DocumentsCatalogActionKind.disabled);
      expect(action.reason, DocumentsCatalogBlockReason.issuedFromBilling);
    });

    test('le reçu reste éteint même hors ligne et élève inconnu', () {
      final action = _resolve(
        EditiqueDocumentType.paymentReceipt,
        studentKnown: false,
        isOffline: true,
      );

      // Le motif le plus structurel prime : ce document ne s'émet pas ici, quel
      // que soit l'état du réseau.
      expect(action.reason, DocumentsCatalogBlockReason.issuedFromBilling);
    });

    group('attestation d inscription', () {
      test('s émet quand le dossier est acquitté', () {
        expect(
          _resolve(EditiqueDocumentType.enrollmentAttestation).kind,
          DocumentsCatalogActionKind.emit,
        );
      });

      // L'attestation est la seule pièce CLÉ-DOSSIER : un élève connu du serveur
      // ne suffit pas, c'est l'`enrollmentId` qui part dans l'URL.
      test('reste éteinte tant que le dossier n est pas acquitté', () {
        final action = _resolve(
          EditiqueDocumentType.enrollmentAttestation,
          enrollmentSyncState: SyncState.pendingSync,
        );

        expect(action.kind, DocumentsCatalogActionKind.disabled);
        expect(
          action.reason,
          DocumentsCatalogBlockReason.enrollmentPendingSync,
        );
      });

      test('reste éteinte sur un dossier en erreur de synchro', () {
        expect(
          _resolve(
            EditiqueDocumentType.enrollmentAttestation,
            enrollmentSyncState: SyncState.syncError,
          ).reason,
          DocumentsCatalogBlockReason.enrollmentPendingSync,
        );
      });

      // Lien profond rechargé : `extra` est perdu, donc l'`enrollmentId` aussi.
      test('signale l absence de référence de dossier', () {
        final action = _resolve(
          EditiqueDocumentType.enrollmentAttestation,
          enrollmentId: '',
        );

        expect(action.reason, DocumentsCatalogBlockReason.missingEnrollmentRef);
      });

      test('reste muette tant que la lecture locale n a pas tranché', () {
        final action = _resolve(
          EditiqueDocumentType.enrollmentAttestation,
          enrollmentSyncState: null,
          isDossierLoaded: false,
        );

        expect(action.kind, DocumentsCatalogActionKind.disabled);
        expect(action.reason, DocumentsCatalogBlockReason.resolving);
      });

      // Une lecture TERMINÉE qui n'a rien donné doit s'expliquer. Sans cette
      // distinction, une base illisible laissait la ligne éteinte ET muette
      // pour toujours — un cul-de-sac sans issue ni message.
      test('s explique quand la lecture a rendu sans rien trouver', () {
        final action = _resolve(
          EditiqueDocumentType.enrollmentAttestation,
          enrollmentSyncState: null,
          isDossierLoaded: true,
        );

        expect(action.kind, DocumentsCatalogActionKind.disabled);
        expect(action.reason, DocumentsCatalogBlockReason.enrollmentUnreadable);
      });

      test('passe à Consulter quand une pièce définitive est connue', () {
        final action = _resolve(
          EditiqueDocumentType.enrollmentAttestation,
          knownPieces: [_piece(docType: 'AI')],
        );

        expect(action.kind, DocumentsCatalogActionKind.consult);
        expect(action.knownPiece?.number, 'ETL-AI-2526-000431');
      });

      // Un `PROV-…` n'a aucune valeur probante et n'est pas le numéro que le
      // serveur re-servira : il ne fait pas passer la ligne à « Consulter ».
      test('ignore une pièce encore provisoire', () {
        final action = _resolve(
          EditiqueDocumentType.enrollmentAttestation,
          knownPieces: [
            _piece(docType: 'AI', status: 'PROVISIONAL', number: 'PROV-ABCD'),
          ],
        );

        expect(action.kind, DocumentsCatalogActionKind.emit);
        expect(action.knownPiece, isNull);
      });

      test('ignore une pièce définitive d un autre type', () {
        expect(
          _resolve(
            EditiqueDocumentType.enrollmentAttestation,
            knownPieces: [_piece(docType: 'RC')],
          ).kind,
          DocumentsCatalogActionKind.emit,
        );
      });
    });

    group('pièces scopées élève', () {
      for (final type in const [
        EditiqueDocumentType.notePerception,
        EditiqueDocumentType.accountStatement,
        EditiqueDocumentType.financialClearance,
      ]) {
        test('${type.code} : éteinte si l élève est inconnu du serveur', () {
          final action = _resolve(type, studentKnown: false);

          expect(action.kind, DocumentsCatalogActionKind.disabled);
          expect(action.reason, DocumentsCatalogBlockReason.pendingSync);
        });

        test('${type.code} : muette tant que l éligibilité est en cours', () {
          expect(
            _resolve(type, studentKnown: null).reason,
            DocumentsCatalogBlockReason.resolving,
          );
        });

        test('${type.code} : éteinte hors ligne, avec un motif', () {
          final action = _resolve(type, isOffline: true);

          expect(action.kind, DocumentsCatalogActionKind.disabled);
          expect(action.reason, DocumentsCatalogBlockReason.offline);
        });
      }

      // Pièce figée : une note de perception déjà connue se consulte.
      test('la note de perception s émet faute de trace locale', () {
        final action = _resolve(EditiqueDocumentType.notePerception);

        expect(action.kind, DocumentsCatalogActionKind.emit);
        expect(action.needsConfirmation, isFalse);
      });

      // Pièces horodatées : chaque appel brûle un numéro de séquence côté
      // serveur, donc confirmation obligatoire — et jamais « Consulter », qui
      // laisserait croire qu'on rouvre une pièce déjà produite.
      test('relevé et quitus exigent une confirmation', () {
        for (final type in const [
          EditiqueDocumentType.accountStatement,
          EditiqueDocumentType.financialClearance,
        ]) {
          final action = _resolve(type);
          expect(action.kind, DocumentsCatalogActionKind.generate);
          expect(action.needsConfirmation, isTrue);
        }
      });

      test('une pièce horodatée ne passe jamais à Consulter', () {
        final action = _resolve(
          EditiqueDocumentType.accountStatement,
          knownPieces: [_piece(docType: 'RL')],
        );

        expect(action.kind, DocumentsCatalogActionKind.generate);
      });
    });

    test('l éligibilité prime sur le hors-ligne', () {
      final action = _resolve(
        EditiqueDocumentType.notePerception,
        studentKnown: false,
        isOffline: true,
      );

      expect(action.reason, DocumentsCatalogBlockReason.pendingSync);
    });

    test('seule une action éteinte porte un motif', () {
      final enabled = _resolve(EditiqueDocumentType.notePerception);

      expect(enabled.isEnabled, isTrue);
      expect(enabled.reason, isNull);
    });
  });

  // Une pièce que l'école a retirée n'est plus une copie qu'on ressort : c'est
  // un fait qu'on explique. Elle ne porte donc aucun geste, mais elle ne
  // disparaît pas pour autant — la taire ferait retomber la ligne sur
  // « Émettre » sans jamais dire pourquoi le papier d'hier n'a plus cours.
  group('pièce annulée', () {
    EditiqueCacheEntry cancelled({
      String docType = 'AI',
      String id = 'c-annulee',
      String documentId = 'doc-annule',
      String documentNumber = 'ETL-AI-2526-000431',
      String? contentSha256 = 'abc',
      String? reason = 'Erreur de classe',
    }) => _cached(
      docType: docType,
      id: id,
      documentId: documentId,
      documentNumber: documentNumber,
      contentSha256: contentSha256,
      cancelledAt: 1786013000000,
      cancellationReason: reason,
    );

    test('n ouvre jamais « Consulter », même avec ses octets', () {
      final action = _resolve(
        EditiqueDocumentType.enrollmentAttestation,
        cachedPieces: [cancelled()],
      );

      expect(action.kind, isNot(DocumentsCatalogActionKind.consult));
      expect(action.cachedPiece, isNull);
      expect(action.isRestitution, isFalse);
    });

    // Le geste que le user a tranché : la pièce se réémet. Le serveur traite
    // une pièce annulée comme absente et en scellera une neuve.
    test('laisse « Émettre » possible en ligne', () {
      final action = _resolve(
        EditiqueDocumentType.enrollmentAttestation,
        cachedPieces: [cancelled()],
      );

      expect(action.kind, DocumentsCatalogActionKind.emit);
      expect(action.isEnabled, isTrue);
      expect(action.cancelledPiece?.cancellationReason, 'Erreur de classe');
    });

    // La trace locale porte encore le numéro de la pièce retirée, mais le
    // serveur ne le re-servira plus : annoncer « Consulter » dirait le
    // contraire de ce qui va se passer.
    test('force « Émettre » malgré une trace locale définitive', () {
      final action = _resolve(
        EditiqueDocumentType.enrollmentAttestation,
        knownPieces: [_piece(docType: 'AI')],
        cachedPieces: [cancelled()],
      );

      expect(action.kind, DocumentsCatalogActionKind.emit);
      expect(action.knownPiece, isNotNull);
    });

    // Hors ligne, la ligne s'éteint comme sans copie — mais elle DIT le
    // retrait, qui est justement ce que le guichet a besoin d'expliquer quand
    // il n'a plus le serveur pour le faire.
    test('éteint la ligne hors ligne, sans taire le retrait', () {
      final action = _resolve(
        EditiqueDocumentType.enrollmentAttestation,
        isOffline: true,
        cachedPieces: [cancelled()],
      );

      expect(action.kind, DocumentsCatalogActionKind.disabled);
      expect(action.reason, DocumentsCatalogBlockReason.offline);
      expect(action.cancelledPiece, isNotNull);
    });

    // Le motif vit dans l'index, donc il survit à l'éviction des octets.
    test('se signale encore une fois ses octets évincés', () {
      final action = _resolve(
        EditiqueDocumentType.enrollmentAttestation,
        cachedPieces: [cancelled(contentSha256: null)],
      );

      expect(action.cancelledPiece?.hasBytes, isFalse);
      expect(action.cancelledPiece?.cancellationReason, 'Erreur de classe');
    });

    // Une pièce retirée ne masque pas une pièce plus ancienne qui, elle, tient
    // toujours : le sélecteur ne s'arrête pas à la première ligne du type.
    test('ne masque pas une copie plus ancienne restée valable', () {
      final action = _resolve(
        EditiqueDocumentType.enrollmentAttestation,
        cachedPieces: [
          cancelled(),
          _cached(
            docType: 'AI',
            id: 'c-valide',
            documentId: 'doc-valide',
            documentNumber: 'ETL-AI-2526-000200',
          ),
        ],
      );

      expect(action.kind, DocumentsCatalogActionKind.consult);
      expect(action.cachedPiece?.documentId, 'doc-valide');
      // Et rien n'est annoncé : la ligne dit ce qu'elle propose, et ce
      // qu'elle propose n'a pas été retiré.
      expect(action.cancelledPiece, isNull);
    });

    test('ne confond pas les types', () {
      final action = _resolve(
        EditiqueDocumentType.notePerception,
        cachedPieces: [cancelled()],
      );

      expect(action.cancelledPiece, isNull);
    });

    // LE défaut trouvé par la revue adversariale. Annuler puis réémettre est le
    // flux NOMINAL — la migration back V74 est bâtie pour lui —, et les deux
    // lignes descendent par le delta sans octets. Parcourir jusqu'à trouver une
    // annulée faisait annoncer « Pièce annulée » alors qu'une remplaçante en
    // vigueur existait, et d'autant plus longtemps qu'on était hors ligne — au
    // seul moment où rien ne peut détromper l'agent.
    test('ne s annonce plus dès qu une pièce lui a succédé', () {
      final action = _resolve(
        EditiqueDocumentType.enrollmentAttestation,
        cachedPieces: [
          // Ordre de l'index : la plus récemment émise d'abord.
          _cached(
            docType: 'AI',
            id: 'c-remplacante',
            documentId: 'doc-remplacante',
            documentNumber: 'ETL-AI-2526-000432',
            contentSha256: null, // apprise par le delta, sans octets
          ),
          cancelled(),
        ],
      );

      expect(action.cancelledPiece, isNull);
    });

    // Symétrique : tant que rien n'a succédé à la pièce retirée, elle reste la
    // dernière nouvelle du type et doit se dire.
    test('s annonce quand rien ne lui a succédé', () {
      final action = _resolve(
        EditiqueDocumentType.enrollmentAttestation,
        cachedPieces: [
          cancelled(),
          _cached(
            docType: 'AI',
            id: 'c-ancienne',
            documentId: 'doc-ancienne',
            documentNumber: 'ETL-AI-2526-000100',
            contentSha256: null,
          ),
        ],
      );

      expect(action.cancelledPiece?.documentId, 'doc-annule');
    });

    // La garantie qui vivait dans le filtre du use case avant qu'il ne soit
    // retiré : c'est ici, et nulle part ailleurs, qu'on empêche « Consulter »
    // de s'allumer sur des octets absents.
    test('une pièce sans octets ne masque pas une copie détenue', () {
      final action = _resolve(
        EditiqueDocumentType.enrollmentAttestation,
        cachedPieces: [
          _cached(
            docType: 'AI',
            id: 'c-connue',
            documentId: 'doc-connue',
            documentNumber: 'ETL-AI-2526-000500',
            contentSha256: null,
          ),
          _cached(
            docType: 'AI',
            id: 'c-tenue',
            documentId: 'doc-tenue',
            documentNumber: 'ETL-AI-2526-000200',
          ),
        ],
      );

      expect(action.kind, DocumentsCatalogActionKind.consult);
      expect(action.cachedPiece?.documentId, 'doc-tenue');
    });

    // Le retrait sans motif reste un retrait : le serveur descend une donnée
    // que le front ne contrôle pas.
    test('se signale même sans motif', () {
      final action = _resolve(
        EditiqueDocumentType.enrollmentAttestation,
        cachedPieces: [cancelled(reason: null)],
      );

      expect(action.cancelledPiece?.isCancelled, isTrue);
      expect(action.cancelledPiece?.cancellationReason, isNull);
    });
  });
}
