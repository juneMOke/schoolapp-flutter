import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';

/// Attribution d'une écriture d'outbox — la brique que le moteur consulte
/// AVANT tout appel réseau (cf. `outbox_author.dart`).
///
/// La règle cardinale testée ici : le doute profite toujours à l'ENVOI. Bloquer
/// à tort est un dommage silencieux ; laisser partir produit au pire un refus
/// visible que la feuille de reprise sait montrer.
void main() {
  OutboxEntry entryWith(
    String payload, {
    int createdAt = 1000,
    String id = 'e',
  }) => OutboxEntry(
    id: id,
    aggregateType: 'ENROLLMENT',
    aggregateId: 'agg-$id',
    operation: OutboxOperation.create,
    payload: payload,
    createdAt: createdAt,
  );

  String payloadOf(String? authorId) =>
      jsonEncode({kOutboxAuthorIdKey: ?authorId, 'x': 1});

  group('outboxAuthorUidOf', () {
    test('lit la clé racine authorId', () {
      expect(outboxAuthorUidOf(payloadOf('uid-a')), 'uid-a');
    });

    test('clé absente → non attribué', () {
      expect(outboxAuthorUidOf(payloadOf(null)), kUnattributedOutboxAuthor);
    });

    test('chaîne vide → non attribué (pas un auteur nommé "")', () {
      expect(outboxAuthorUidOf(payloadOf('')), kUnattributedOutboxAuthor);
    });

    test('authorId non textuel → non attribué, sans lever', () {
      expect(outboxAuthorUidOf('{"authorId": 42}'), kUnattributedOutboxAuthor);
    });

    test('payload illisible → non attribué, sans lever : un JSON corrompu ne '
        'doit jamais faire échouer un flush', () {
      expect(outboxAuthorUidOf('{ pas du json'), kUnattributedOutboxAuthor);
      expect(outboxAuthorUidOf(''), kUnattributedOutboxAuthor);
      expect(outboxAuthorUidOf('[1,2,3]'), kUnattributedOutboxAuthor);
    });

    test('ignore un authorId IMBRIQUÉ : seule la racine fait foi, comme côté '
        'serveur', () {
      expect(
        outboxAuthorUidOf('{"payload":{"authorId":"uid-a"}}'),
        kUnattributedOutboxAuthor,
      );
    });
  });

  group('isForeignOutboxAuthor', () {
    test('auteur identifié différent du porteur → étrangère', () {
      expect(isForeignOutboxAuthor(payloadOf('uid-a'), 'uid-b'), isTrue);
    });

    test('même auteur → jamais étrangère', () {
      expect(isForeignOutboxAuthor(payloadOf('uid-a'), 'uid-a'), isFalse);
    });

    test('porteur sans uid (backend hérité sans le claim) → on ne filtre '
        'rien, comportement d\'avant la garde', () {
      expect(isForeignOutboxAuthor(payloadOf('uid-a'), null), isFalse);
      expect(isForeignOutboxAuthor(payloadOf('uid-a'), ''), isFalse);
    });

    test('entrée non attribuée → poussable par le porteur courant : la geler '
        'l\'orphelinerait à vie, aucun compte ne pourrait la réclamer', () {
      expect(isForeignOutboxAuthor(payloadOf(null), 'uid-b'), isFalse);
      expect(isForeignOutboxAuthor('{ corrompu', 'uid-b'), isFalse);
    });
  });

  group('summarizeOtherAuthors', () {
    test('ne retient que les entrées d\'autres comptes identifiés', () {
      final summary = summarizeOtherAuthors([
        entryWith(payloadOf('uid-a'), id: '1', createdAt: 3000),
        entryWith(payloadOf('uid-b'), id: '2', createdAt: 2000), // le porteur
        entryWith(payloadOf(null), id: '3', createdAt: 1000), // non attribuée
        entryWith(payloadOf('uid-c'), id: '4', createdAt: 5000),
      ], 'uid-b');

      expect(summary.count, 2);
      expect(summary.authorUids, ['uid-a', 'uid-c']);
    });

    test('retient la PLUS ANCIENNE, quel que soit l\'ordre d\'itération', () {
      final summary = summarizeOtherAuthors([
        entryWith(payloadOf('uid-a'), id: '1', createdAt: 9000),
        entryWith(payloadOf('uid-a'), id: '2', createdAt: 4000),
        entryWith(payloadOf('uid-a'), id: '3', createdAt: 7000),
      ], 'uid-b');

      expect(summary.count, 3);
      expect(summary.oldestCreatedAt, 4000);
      expect(summary.authorUids, ['uid-a'], reason: 'dédoublonné');
    });

    test('rien d\'étranger → agrégat vide, pas de bande affichée', () {
      final summary = summarizeOtherAuthors([
        entryWith(payloadOf('uid-b'), id: '1'),
        entryWith(payloadOf(null), id: '2'),
      ], 'uid-b');

      expect(summary.isEmpty, isTrue);
      expect(summary.oldestCreatedAt, isNull);
      expect(summary.authorUids, isEmpty);
    });

    test('porteur inconnu → aucune entrée n\'est étrangère', () {
      final summary = summarizeOtherAuthors([
        entryWith(payloadOf('uid-a'), id: '1'),
      ], null);

      expect(summary.isEmpty, isTrue);
    });
  });
}
