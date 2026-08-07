import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_blob_cipher.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_blob_store.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_dao.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_key_service.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_maintenance_dao.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_document_cache.dart';
import 'package:school_app_flutter/features/documents/domain/cache/editique_cache_entitlement.dart';
import 'package:school_app_flutter/features/documents/domain/cache/editique_cache_eviction_policy.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';

class _FakeKeyService implements EditiqueCacheKeyService {
  final Uint8List bytes = Uint8List.fromList(
    List<int>.generate(32, (i) => i & 0xFF),
  );

  @override
  Future<EditiqueCacheKey> getOrCreate() async =>
      EditiqueCacheKey(bytes: bytes, createdNow: false);

  @override
  Future<void> destroy() async {}
}

/// Profil autorisé : la garde de profil est éprouvée ailleurs, ce fichier
/// s'intéresse à ce que le delta apporte.
class _FakeAccess implements EditiqueCacheAccess {
  @override
  Future<bool> isEntitled() async => true;
}

class _FakeIds implements IdGenerator {
  int _next = 0;

  @override
  String newId() => 'gen-${++_next}';
}

/// Ce que le delta de synchronisation apporte au cache — et surtout ce qu'il ne
/// doit jamais lui retirer.
void main() {
  late Database db;
  late Directory base;
  late Directory cacheDir;
  late EditiqueDocumentCache cache;
  late EditiqueCacheDao index;
  late _FakeAccess access;

  Uint8List pdf(String marque) => Uint8List.fromList(
    [
      '%PDF-1.4 $marque'.codeUnits,
      List<int>.filled(200, 32),
    ].expand((e) => e).toList(),
  );

  setUp(() async {
    db = await openFullOfflineDb();
    base = await Directory.systemTemp.createTemp('eteelo-editique-pull-');
    cacheDir = Directory(p.join(base.path, 'editique_cache'));
    index = EditiqueCacheDao(db);
    access = _FakeAccess();
    cache = EditiqueDocumentCache(
      index: index,
      maintenance: EditiqueCacheMaintenanceDao(db),
      store: EditiqueBlobStore(
        keyService: _FakeKeyService(),
        cipher: runEditiqueCipherTask,
        baseDirectory: () async => base,
      ),
      ids: _FakeIds(),
      access: access,
      now: () => 1000,
    );
  });

  tearDown(() async {
    await db.close();
    if (await base.exists()) await base.delete(recursive: true);
  });

  EditiqueCacheEntry known({
    String documentId = 'doc-1',
    String documentNumber = 'ETL-NP-2526-000001',
    String docType = 'NP',
    String? studentId = 's-1',
    int sizeBytes = 4096,
    int? cancelledAt,
    String? cancellationReason,
  }) => EditiqueCacheEntry(
    id: 'ignoré',
    documentId: documentId,
    documentNumber: documentNumber,
    docType: docType,
    studentId: studentId,
    academicYearId: 'y-1',
    schoolId: 'school-1',
    sizeBytes: sizeBytes,
    emittedAt: 500,
    cancelledAt: cancelledAt,
    cancellationReason: cancellationReason,
    createdAt: 1000,
    lastAccessedAt: 1000,
  );

  group('ce que le delta apprend', () {
    test('indexe une pièce sans en détenir les octets', () async {
      expect(await cache.recordKnownDocuments([known()]), 1);

      final entry = await index.findByDocumentId('doc-1');
      expect(entry, isNotNull);
      expect(entry!.hasBytes, isFalse);
      expect(entry.sizeBytes, 4096, reason: 'le poids annoncé est conservé');
      // Rien n'a été écrit sur le disque : un delta ne transporte pas d'octets.
      expect(cacheDir.existsSync(), isFalse);
    });

    // Le budget mesure ce que la tablette OCCUPE. Compter un catalogue ferait
    // balayer l'éviction pour libérer une place déjà libre.
    test('une pièce seulement connue ne pèse pas au budget', () async {
      await cache.recordKnownDocuments([known(sizeBytes: 900000)]);

      expect(await index.totalSizeBytes(), 0);
    });

    test(
      'une pièce seulement connue ne se lit pas, et ne disparaît pas',
      () async {
        await cache.recordKnownDocuments([known()]);

        expect(await cache.readByDocumentId('doc-1'), isNull);
        expect(
          await index.findByDocumentId('doc-1'),
          isNotNull,
          reason: 'la connaissance survit au défaut de cache',
        );
      },
    );

    // Le serveur n'archive ni relevé ni quitus : une ligne de ce type ne peut
    // pas venir du delta, et si elle venait elle ne doit pas entrer.
    test('refuse en silence ce que le cache n admet pas', () async {
      final retained = await cache.recordKnownDocuments([
        known(documentId: 'doc-rl', documentNumber: 'ETL-RL-1', docType: 'RL'),
        known(documentId: '', documentNumber: ''),
      ]);

      expect(retained, 0);
      expect(await index.count(), 0);
    });

    test('un lot vide ne fait rien', () async {
      expect(await cache.recordKnownDocuments(const []), 0);
    });
  });

  // Le défaut que la revue du lot précédent a rendu visible : sans garde, le
  // premier cycle de pull viderait le cache de ce que la tablette possède.
  group('ce que le delta ne doit jamais retirer', () {
    test('ne dégrade pas une pièce détenue en simple connaissance', () async {
      await cache.put(
        docType: 'NP',
        documentId: 'doc-1',
        documentNumber: 'ETL-NP-2526-000001',
        studentId: 's-1',
        academicYearId: 'y-1',
        schoolId: 'school-1',
        bytes: pdf('note'),
      );
      final avant = await index.findByDocumentId('doc-1');
      expect(avant!.hasBytes, isTrue);

      await cache.recordKnownDocuments([known()]);

      final apres = await index.findByDocumentId('doc-1');
      expect(apres!.hasBytes, isTrue, reason: 'l empreinte survit au delta');
      expect(apres.contentSha256, avant.contentSha256);
      expect(apres.sizeBytes, avant.sizeBytes);
      expect(apres.id, avant.id, reason: 'la clé locale nomme le fichier');
      // Et la pièce se relit toujours.
      expect(await cache.readByDocumentId('doc-1'), equals(pdf('note')));
    });

    test('n évince jamais une pièce qu il vient d apprendre', () async {
      // Budget minuscule : sans la garde, un catalogue de 900 Ko déclencherait
      // un balayage qui n'aurait rien à libérer.
      final serre = EditiqueDocumentCache(
        index: index,
        maintenance: EditiqueCacheMaintenanceDao(db),
        store: EditiqueBlobStore(
          keyService: _FakeKeyService(),
          cipher: runEditiqueCipherTask,
          baseDirectory: () async => base,
        ),
        ids: _FakeIds(),
        access: access,
        policy: const EditiqueCacheEvictionPolicy(
          budgetBytes: 1000,
          targetRatio: 0.5,
        ),
        now: () => 1000,
      );

      await serre.recordKnownDocuments([
        known(documentId: 'a', documentNumber: 'N-a', sizeBytes: 900000),
        known(documentId: 'b', documentNumber: 'N-b', sizeBytes: 900000),
      ]);

      expect(await serre.sweepToBudget(), 0);
      expect(await index.count(), 2);
    });

    // Ce qu'« évincer » veut dire : retirer des octets, pas une connaissance.
    // Le curseur du delta est monotone — une ligne supprimée ne redescendrait
    // jamais, et la pièce disparaîtrait du catalogue pour toujours alors que le
    // serveur la conserve.
    test('une éviction rétrograde la ligne, elle ne la supprime pas', () async {
      final serre = EditiqueDocumentCache(
        index: index,
        maintenance: EditiqueCacheMaintenanceDao(db),
        store: EditiqueBlobStore(
          keyService: _FakeKeyService(),
          cipher: runEditiqueCipherTask,
          baseDirectory: () async => base,
        ),
        ids: _FakeIds(),
        access: access,
        policy: const EditiqueCacheEvictionPolicy(
          budgetBytes: 300,
          targetRatio: 0.5,
        ),
        now: () => 1000,
      );
      await serre.put(
        docType: 'RC',
        documentId: 'doc-1',
        documentNumber: 'ETL-RC-1',
        schoolId: 'school-1',
        bytes: pdf('reçu'),
      );
      await serre.put(
        docType: 'NP',
        documentId: 'doc-2',
        documentNumber: 'ETL-NP-2',
        schoolId: 'school-1',
        bytes: pdf('note'),
      );

      // Le balayage a déjà eu lieu : `put` le déclenche dès que le budget est
      // franchi. C'est son EFFET qu'on regarde, pas un second appel.
      // La connaissance survit : le catalogue continue de savoir que la pièce
      // existe, et elle reste re-téléchargeable.
      expect(await index.count(), 2);
      final downgraded = await index.findByDocumentId('doc-1');
      expect(downgraded!.hasBytes, isFalse);
      expect(downgraded.sizeBytes, 0, reason: 'ne pèse plus au budget');
      expect(
        downgraded.documentNumber,
        'ETL-RC-1',
        reason: 'toujours adressable',
      );
      expect(
        cacheDir.listSync(),
        isEmpty,
        reason: 'les octets, eux, sont partis',
      );
      expect(await index.totalSizeBytes(), 0);
    });

    // Une ligne sans fichier ne doit pas protéger un fichier, ni en faire
    // réclamer un qui n'existe pas.
    test('ne perturbe pas la réclamation des orphelins', () async {
      await cache.put(
        docType: 'RC',
        documentId: 'doc-rc',
        documentNumber: 'ETL-RC-1',
        schoolId: 'school-1',
        bytes: pdf('reçu'),
      );
      await cache.recordKnownDocuments([known()]);

      expect(await cache.reclaimOrphans(), 0);
      expect(cacheDir.listSync(), hasLength(1));
    });
  });

  // L'annulation n'atteint la tablette QUE par ce chemin. Elle entre en tension
  // apparente avec le groupe ci-dessus — « ne dégrade jamais une pièce
  // détenue » —, et c'est voulu : le delta ne retire toujours rien. Une pièce
  // retirée par l'école GARDE ses octets, parce qu'un guichet doit pouvoir
  // ressortir le papier qu'une famille lui présente pour lui expliquer qu'il
  // n'a plus cours. Le delta ajoute une information ; il n'en soustrait aucune.
  group('ce que le delta apprend d une annulation', () {
    test('marque une pièce détenue sans lui retirer ses octets', () async {
      await cache.put(
        docType: 'NP',
        documentId: 'doc-1',
        documentNumber: 'ETL-NP-2526-000001',
        studentId: 's-1',
        schoolId: 'school-1',
        bytes: pdf('note'),
      );
      final avant = await index.findByDocumentId('doc-1');
      expect(avant!.isCancelled, isFalse);

      await cache.recordKnownDocuments([
        known(cancelledAt: 1786013000000, cancellationReason: 'Doublon'),
      ]);

      final apres = await index.findByDocumentId('doc-1');
      expect(apres!.isCancelled, isTrue);
      expect(apres.cancellationReason, 'Doublon');
      // Les octets restent, et le fichier avec.
      expect(apres.hasBytes, isTrue);
      expect(apres.contentSha256, avant.contentSha256);
      expect(await cache.readByDocumentId('doc-1'), equals(pdf('note')));
      expect(cacheDir.listSync(), hasLength(1));
    });

    test('une pièce annulée pèse toujours au budget', () async {
      await cache.put(
        docType: 'NP',
        documentId: 'doc-1',
        documentNumber: 'ETL-NP-2526-000001',
        schoolId: 'school-1',
        bytes: pdf('note'),
      );
      final avant = await index.totalSizeBytes();

      await cache.recordKnownDocuments([known(cancelledAt: 1786013000000)]);

      expect(await index.totalSizeBytes(), avant);
      expect(avant, greaterThan(0));
    });

    test('apprend une pièce annulée jamais détenue', () async {
      await cache.recordKnownDocuments([
        known(cancelledAt: 1786013000000, cancellationReason: 'Erreur'),
      ]);

      final entry = await index.findByDocumentId('doc-1');
      expect(entry!.isCancelled, isTrue);
      expect(entry.cancellationReason, 'Erreur');
      expect(entry.hasBytes, isFalse);
    });

    // Côté serveur l'annulation est définitive : rien ne la lève. Un cycle
    // ultérieur qui redescendrait la pièce sans son retrait — champ omis,
    // ligne partiellement lue — ne doit donc pas la remettre en vigueur.
    test('un cycle ultérieur muet ne lève pas l annulation', () async {
      await cache.recordKnownDocuments([
        known(cancelledAt: 1786013000000, cancellationReason: 'Doublon'),
      ]);

      await cache.recordKnownDocuments([known()]);

      final entry = await index.findByDocumentId('doc-1');
      expect(entry!.isCancelled, isTrue);
      expect(entry.cancellationReason, 'Doublon');
    });

    // Une pièce en vigueur ne doit pas hériter du retrait d'une autre : la
    // préservation se fait ligne à ligne, jamais globalement.
    test('n annule pas les pièces voisines', () async {
      await cache.recordKnownDocuments([
        known(cancelledAt: 1786013000000),
        known(documentId: 'doc-2', documentNumber: 'ETL-NP-2', docType: 'AI'),
      ]);

      expect((await index.findByDocumentId('doc-1'))!.isCancelled, isTrue);
      expect((await index.findByDocumentId('doc-2'))!.isCancelled, isFalse);
    });
  });
}
