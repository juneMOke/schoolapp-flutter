import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/documents/data/models/editique_document_pull_models.dart';

/// Parsing du delta éditique (`GET /api/v1/sync/editique-documents`).
///
/// Ce fichier n'était couvert par aucun test avant l'annulation, ce qui est
/// exactement ce qui le rend dangereux : `_lenientList` **avale** toute ligne
/// dont le `fromJson` lève, pour éviter qu'une page empoisonnée ne fige la
/// ressource pour toujours. Un mauvais typage n'y produit donc ni exception ni
/// journal — la pièce disparaît du delta, en silence.
///
/// Et l'annulation transite intégralement par ici : un champ non lu la rendrait
/// invisible partout en aval sans qu'aucun autre test ne rougisse.
void main() {
  Map<String, dynamic> payload({
    Object? cancelledAt,
    Object? cancellationReason,
    Object? emittedAt = '2026-06-12T00:00:00Z',
  }) => {
    'id': 'doc-1',
    'docType': 'RC',
    'documentNumber': 'ETL-RC-2526-000212',
    'studentId': 's-1',
    'academicYearId': 'y-1',
    'emittedAt': emittedAt,
    'sizeBytes': 120000,
    'contentSha256': 'a' * 64,
    if (cancelledAt != null) 'cancelledAt': cancelledAt,
    if (cancellationReason != null) 'cancellationReason': cancellationReason,
  };

  group('PulledEditiqueDocument.fromJson', () {
    test('lit une pièce en vigueur', () {
      final document = PulledEditiqueDocument.fromJson(payload());

      expect(document.id, 'doc-1');
      expect(document.documentNumber, 'ETL-RC-2526-000212');
      expect(document.sizeBytes, 120000);
      expect(document.cancelledAtMs, isNull);
      expect(document.cancellationReason, isNull);
    });

    test('lit le retrait et son motif', () {
      final document = PulledEditiqueDocument.fromJson(
        payload(
          cancelledAt: '2026-08-06T09:30:00Z',
          cancellationReason: 'Erreur de montant',
        ),
      );

      expect(
        document.cancelledAtMs,
        DateTime.utc(2026, 8, 6, 9, 30).millisecondsSinceEpoch,
      );
      expect(document.cancellationReason, 'Erreur de montant');
    });

    // Le wire est UTC. Un ISO **naïf** serait sinon lu en heure locale, ce qui
    // décalerait l'instant du fuseau de l'appareil.
    test('lit une date de retrait sans fuseau comme de l UTC', () {
      final document = PulledEditiqueDocument.fromJson(
        payload(cancelledAt: '2026-08-06T09:30:00'),
      );

      expect(
        document.cancelledAtMs,
        DateTime.utc(2026, 8, 6, 9, 30).millisecondsSinceEpoch,
      );
    });

    test('une date de retrait illisible ne fait pas perdre la pièce', () {
      final document = PulledEditiqueDocument.fromJson(
        payload(cancelledAt: 'pas une date'),
      );

      expect(document.id, 'doc-1');
      expect(document.cancelledAtMs, isNull);
    });

    // Le serveur ne pose jamais l'un sans l'autre, mais le front reçoit ici une
    // donnée qu'il ne contrôle pas : la lecture ne doit pas exiger la paire.
    test('lit un retrait sans motif', () {
      final document = PulledEditiqueDocument.fromJson(
        payload(cancelledAt: '2026-08-06T09:30:00Z'),
      );

      expect(document.cancelledAtMs, isNotNull);
      expect(document.cancellationReason, isNull);
    });
  });

  group('toCacheEntry', () {
    test('porte le retrait jusqu à l index', () {
      final entry = PulledEditiqueDocument.fromJson(
        payload(
          cancelledAt: '2026-08-06T09:30:00Z',
          cancellationReason: 'Doublon',
        ),
      ).toCacheEntry(schoolId: 'school-1', nowMs: 5000);

      expect(entry.isCancelled, isTrue);
      expect(
        entry.cancelledAt,
        DateTime.utc(2026, 8, 6, 9, 30).millisecondsSinceEpoch,
      );
      expect(entry.cancellationReason, 'Doublon');
    });

    // L'empreinte du serveur n'entre JAMAIS dans l'index : cette colonne dit
    // « la tablette détient ces octets-là ». Une pièce annulée descendue par le
    // delta n'est donc pas plus détenue qu'une autre.
    test('n annonce pas des octets que la tablette n a pas', () {
      final entry = PulledEditiqueDocument.fromJson(
        payload(cancelledAt: '2026-08-06T09:30:00Z'),
      ).toCacheEntry(schoolId: 'school-1', nowMs: 5000);

      expect(entry.hasBytes, isFalse);
      expect(entry.contentSha256, isNull);
    });

    test('une pièce en vigueur n arrive pas annulée', () {
      final entry = PulledEditiqueDocument.fromJson(
        payload(),
      ).toCacheEntry(schoolId: 'school-1', nowMs: 5000);

      expect(entry.isCancelled, isFalse);
      expect(entry.cancellationReason, isNull);
    });
  });

  group('EditiqueDocumentPageDto.fromJson', () {
    test('lit une page et ses annulations', () {
      final page = EditiqueDocumentPageDto.fromJson({
        'items': [
          payload(),
          {
            ...payload(cancelledAt: '2026-08-06T09:30:00Z'),
            'id': 'doc-2',
            'documentNumber': 'ETL-AI-2526-000007',
            'docType': 'AI',
          },
        ],
        'hasMore': false,
        'serverTime': '2026-08-06T10:00:00Z',
      });

      expect(page.items, hasLength(2));
      expect(page.items.first.cancelledAtMs, isNull);
      expect(page.items.last.cancelledAtMs, isNotNull);
    });

    // Le comportement qui rend ce fichier dangereux, épinglé pour qu'il reste
    // un choix : la ligne écartée reviendra au prochain delta une fois le
    // serveur corrigé, alors qu'une page empoisonnée figerait la ressource.
    test('écarte une ligne malformée sans perdre la page', () {
      final page = EditiqueDocumentPageDto.fromJson({
        'items': [
          {'docType': 'RC'}, // pas d'`id` : `fromJson` lève
          payload(),
        ],
        'hasMore': false,
        'serverTime': '2026-08-06T10:00:00Z',
      });

      expect(page.items, hasLength(1));
      expect(page.items.single.id, 'doc-1');
    });
  });
}
