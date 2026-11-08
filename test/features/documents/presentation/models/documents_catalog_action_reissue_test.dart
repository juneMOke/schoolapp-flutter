import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_catalog_entry.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';
import 'package:school_app_flutter/features/documents/presentation/models/documents_catalog_action.dart';

DocumentsCatalogAction _resolve(
  EditiqueDocumentType type, {
  bool isOffline = false,
  SyncState? enrollmentSyncState = SyncState.synced,
  List<EditiqueCacheEntry> cachedPieces = const <EditiqueCacheEntry>[],
}) => DocumentsCatalogAction.resolve(
  entry: EditiqueCatalogEntry.all.firstWhere((e) => e.type == type),
  isStudentKnownToServer: true,
  isOffline: isOffline,
  enrollmentId: 'e-1',
  enrollmentSyncState: enrollmentSyncState,
  isDossierLoaded: true,
  knownPieces: const [],
  cachedPieces: cachedPieces,
);

EditiqueCacheEntry _piece(
  String docType, {
  String id = 'c-1',
  String? documentId = 'doc-1',
  String? contentSha256 = 'abc',
  int? cancelledAt,
  int? edition,
}) => EditiqueCacheEntry(
  id: id,
  documentId: documentId,
  documentNumber: 'ETL-$docType-2526-000431',
  docType: docType,
  schoolId: 'school-1',
  sizeBytes: 1024,
  contentSha256: contentSha256,
  cancelledAt: cancelledAt,
  edition: edition,
  createdAt: 1000,
  lastAccessedAt: 1000,
);

void main() {
  group('réémission corrigée', () {
    for (final (type, code) in const [
      (EditiqueDocumentType.enrollmentAttestation, 'AI'),
      (EditiqueDocumentType.notePerception, 'NP'),
      (EditiqueDocumentType.enrollmentSheet, 'FI'),
    ]) {
      test('$code en vigueur, connue par son identifiant : réémissible', () {
        final piece = _piece(code);
        expect(_resolve(type, cachedPieces: [piece]).reissuablePiece, piece);
      });
    }

    test('sans octets sur la tablette : réémissible quand même, le serveur '
        'recompose', () {
      final piece = _piece('AI', contentSha256: null);
      expect(
        _resolve(
          EditiqueDocumentType.enrollmentAttestation,
          cachedPieces: [piece],
        ).reissuablePiece,
        piece,
      );
    });

    test('connue par son seul numéro : rien ne la désigne au serveur', () {
      expect(
        _resolve(
          EditiqueDocumentType.enrollmentAttestation,
          cachedPieces: [_piece('AI', documentId: null)],
        ).reissuablePiece,
        isNull,
      );
    });

    test('hors ligne : pas de réémission', () {
      expect(
        _resolve(
          EditiqueDocumentType.enrollmentAttestation,
          isOffline: true,
          cachedPieces: [_piece('AI')],
        ).reissuablePiece,
        isNull,
      );
    });

    test('pièce annulée : rien à réémettre, la ligne propose Émettre', () {
      final action = _resolve(
        EditiqueDocumentType.enrollmentAttestation,
        cachedPieces: [_piece('AI', cancelledAt: 5)],
      );
      expect(action.reissuablePiece, isNull);
      expect(action.cancelledPiece, isNotNull);
    });

    test('dossier pas encore synchronisé : la garde passe avant', () {
      expect(
        _resolve(
          EditiqueDocumentType.enrollmentAttestation,
          enrollmentSyncState: SyncState.pendingSync,
          cachedPieces: [_piece('AI')],
        ).reissuablePiece,
        isNull,
      );
    });

    test('la remplaçante en vigueur est celle proposée, pas l\'annulée', () {
      final replacement = _piece('AI', id: 'c-2', documentId: 'doc-2');
      final action = _resolve(
        EditiqueDocumentType.enrollmentAttestation,
        cachedPieces: [replacement, _piece('AI', cancelledAt: 5)],
      );
      expect(action.reissuablePiece, replacement);
      expect(action.cachedPiece, replacement);
    });
  });

  test('la dernière pièce est annulée : rien à réémettre, même si une plus '
      'ancienne tient encore', () {
    final action = _resolve(
      EditiqueDocumentType.notePerception,
      cachedPieces: [
        _piece('NP', id: 'c-latest', documentId: 'doc-latest', cancelledAt: 9),
        // Sans octets ici : la ligne propose « Émettre » et annonce le retrait.
        _piece(
          'NP',
          id: 'c-old',
          documentId: 'doc-old',
          edition: 2,
          contentSha256: null,
        ),
      ],
    );
    expect(action.kind, DocumentsCatalogActionKind.emit);
    expect(action.cancelledPiece?.documentId, 'doc-latest');
    expect(action.reissuablePiece, isNull);
    expect(action.currentEdition, isNull);
  });

  group('édition affichée', () {
    test('édition 2 : annoncée', () {
      expect(
        _resolve(
          EditiqueDocumentType.notePerception,
          cachedPieces: [_piece('NP', edition: 2)],
        ).currentEdition,
        2,
      );
    });

    test('édition 1 ou inconnue : rien à annoncer', () {
      for (final edition in const [1, null]) {
        expect(
          _resolve(
            EditiqueDocumentType.notePerception,
            cachedPieces: [_piece('NP', edition: edition)],
          ).currentEdition,
          isNull,
        );
      }
    });

    test('hors ligne aussi : l\'édition est un fait local', () {
      expect(
        _resolve(
          EditiqueDocumentType.notePerception,
          isOffline: true,
          cachedPieces: [_piece('NP', edition: 3)],
        ).currentEdition,
        3,
      );
    });
  });
}
