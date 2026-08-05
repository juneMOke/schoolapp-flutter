import 'dart:async';
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
import 'package:school_app_flutter/features/documents/domain/cache/editique_cache_eviction_policy.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';

class _FakeKeyService implements EditiqueCacheKeyService {
  final Uint8List bytes = Uint8List.fromList(
    List<int>.generate(32, (i) => i & 0xFF),
  );
  int destructions = 0;
  int reads = 0;

  @override
  Future<EditiqueCacheKey> getOrCreate() async {
    reads++;
    return EditiqueCacheKey(bytes: bytes, createdNow: false);
  }

  @override
  Future<void> destroy() async => destructions++;
}

/// Identifiants prévisibles : le nom des fichiers sur le disque est une
/// assertion du lot, il ne doit pas dépendre d'un tirage.
class _FakeIds implements IdGenerator {
  int _next = 0;

  @override
  String newId() => 'gen-${++_next}';
}

/// Index dont l'écriture de la ligne peut être retenue à volonté — le seul
/// moyen de se placer entre la ligne et le fichier, là où ils se contredisent.
class _DaoALaTraine extends EditiqueCacheDao {
  _DaoALaTraine(super.db);

  Completer<void>? pause;

  /// Franchi dès que la ligne est écrite : le test sait alors que l'index est
  /// en avance sur le disque, sans avoir à parier sur un délai.
  final Completer<void> ligneEcrite = Completer<void>();

  /// Fait échouer le marquage d'accès, comme une base pleine ou en cours de
  /// fermeture.
  bool touchLeve = false;

  @override
  Future<void> upsert(EditiqueCacheEntry entry) async {
    await super.upsert(entry);
    final held = pause;
    if (held == null) return;
    if (!ligneEcrite.isCompleted) ligneEcrite.complete();
    await held.future;
  }

  @override
  Future<void> touch({required String id, required int nowMs}) async {
    if (touchLeve) throw StateError('database_closed');
    return super.touch(id: id, nowMs: nowMs);
  }
}

/// Magasin dont on choisit les réponses : une panne passagère et un fichier qui
/// refuse de partir ne se provoquent pas autrement.
class _MagasinRetif extends EditiqueBlobStore {
  _MagasinRetif({
    required super.keyService,
    required super.cipher,
    required super.baseDirectory,
    this.lectureIndisponible = false,
    this.effacementImpossible = false,
  });

  final bool lectureIndisponible;
  final bool effacementImpossible;

  /// Franchi quand la PREMIÈRE relecture a rendu son verdict — donc quand la
  /// restitution a vu le désaccord et s'apprête à demander le verrou.
  final Completer<void> premiereLecture = Completer<void>();

  @override
  Future<EditiqueBlobRead> read(String id) async {
    final result = lectureIndisponible
        ? const EditiqueBlobUnavailable()
        : await super.read(id);
    if (!premiereLecture.isCompleted) premiereLecture.complete();
    return result;
  }

  @override
  Future<bool> delete(String id) async =>
      effacementImpossible ? false : super.delete(id);
}

void main() {
  late Database db;
  late Directory base;
  late Directory cacheDir;
  late _FakeKeyService keys;
  late _FakeIds ids;
  late int clock;

  Uint8List pdf(String marque, {int taille = 200}) => Uint8List.fromList([
    ...'%PDF-1.4 $marque'.codeUnits,
    ...List<int>.filled(taille, 0x20),
  ]);

  setUp(() async {
    db = await openFullOfflineDb();
    base = await Directory.systemTemp.createTemp('eteelo-editique-cache-');
    cacheDir = Directory(p.join(base.path, 'editique_cache'));
    keys = _FakeKeyService();
    ids = _FakeIds();
    clock = 1000;
  });

  tearDown(() async {
    await db.close();
    if (await base.exists()) await base.delete(recursive: true);
  });

  EditiqueDocumentCache cacheWith({
    EditiqueCacheEvictionPolicy? policy,
    EditiqueCipherOffloader? cipher,
    EditiqueCacheDao? index,
    EditiqueBlobStore? store,
  }) => EditiqueDocumentCache(
    index: index ?? EditiqueCacheDao(db),
    maintenance: EditiqueCacheMaintenanceDao(db),
    store:
        store ??
        EditiqueBlobStore(
          keyService: keys,
          cipher: cipher ?? runEditiqueCipherTask,
          baseDirectory: () async => base,
        ),
    ids: ids,
    policy: policy ?? const EditiqueCacheEvictionPolicy(),
    now: () => clock,
  );

  _MagasinRetif magasinRetif({
    bool lectureIndisponible = false,
    bool effacementImpossible = false,
  }) => _MagasinRetif(
    keyService: keys,
    cipher: runEditiqueCipherTask,
    baseDirectory: () async => base,
    lectureIndisponible: lectureIndisponible,
    effacementImpossible: effacementImpossible,
  );

  Future<EditiqueCacheEntry?> putReceipt(
    EditiqueDocumentCache cache, {
    String documentId = 'doc-1',
    String documentNumber = 'ETL-RC-2526-000001',
    String schoolId = 'school-1',
    String docType = 'RC',
    int taille = 200,
    String marque = 'reçu',
  }) {
    return cache.put(
      docType: docType,
      documentId: documentId,
      documentNumber: documentNumber,
      studentId: 's-1',
      academicYearId: 'y-1',
      schoolId: schoolId,
      ownerUid: 'u-1',
      emittedAt: 500,
      bytes: pdf(marque, taille: taille),
    );
  }

  List<String> filesOnDisk() => cacheDir.existsSync()
      ? (cacheDir.listSync().map((f) => p.basename(f.path)).toList()..sort())
      : <String>[];

  group('mise en cache', () {
    test('indexe la pièce et scelle ses octets', () async {
      final cache = cacheWith();

      final entry = await cache.put(
        docType: 'RC',
        documentId: 'doc-1',
        documentNumber: 'ETL-RC-2526-000001',
        studentId: 's-1',
        academicYearId: 'y-1',
        schoolId: 'school-1',
        ownerUid: 'u-1',
        emittedAt: 500,
        bytes: pdf('reçu'),
      );

      expect(entry, isNotNull);
      expect(entry!.id, 'gen-1');
      expect(entry.sizeBytes, pdf('reçu').length);
      expect(entry.createdAt, 1000);
      expect(filesOnDisk(), ['gen-1.enc']);
      expect(await cache.readByDocumentId('doc-1'), equals(pdf('reçu')));
    });

    test('retrouve une pièce par son numéro, à défaut d identifiant', () async {
      final cache = cacheWith();
      await cache.put(
        docType: 'NP',
        documentNumber: 'ETL-NP-2526-000009',
        schoolId: 'school-1',
        bytes: pdf('note'),
      );

      final octets = await cache.readByDocumentNumber(
        schoolId: 'school-1',
        documentNumber: 'ETL-NP-2526-000009',
      );

      expect(octets, equals(pdf('note')));
    });

    // Le serveur ne conserve ni relevé ni quitus : une copie locale en serait
    // l'unique exemplaire au monde, et l'éviction la détruirait. Le refus doit
    // tomber AVANT le moindre octet écrit, sinon le fichier naît orphelin.
    // L'assertion porte sur le nombre de scellements demandés, pas sur l'état
    // final : un refus tardif de l'index laisserait le même disque vide après
    // compensation, et rendrait ce test vert alors que la garde aurait disparu.
    test(
      'refuse une pièce que le serveur n archive pas, sans rien écrire',
      () async {
        var scellements = 0;
        final cache = cacheWith(
          cipher: (request) {
            scellements++;
            return runEditiqueCipherTask(request);
          },
        );

        for (final type in ['RL', 'QT']) {
          expect(
            await cache.put(
              docType: type,
              documentId: 'doc-$type',
              schoolId: 'school-1',
              bytes: pdf(type),
            ),
            isNull,
            reason: type,
          );
        }

        expect(scellements, 0);
        expect(keys.reads, 0, reason: 'pas même une clé de cache fabriquée');
        expect(cacheDir.existsSync(), isFalse);
        expect(await EditiqueCacheDao(db).count(), 0);
      },
    );

    test('refuse une pièce que rien ne permettrait de redemander', () async {
      var scellements = 0;
      final cache = cacheWith(
        cipher: (request) {
          scellements++;
          return runEditiqueCipherTask(request);
        },
      );

      final entry = await cache.put(
        docType: 'RC',
        documentId: '',
        documentNumber: '',
        schoolId: 'school-1',
        bytes: pdf('anonyme'),
      );

      expect(entry, isNull);
      expect(scellements, 0);
      expect(cacheDir.existsSync(), isFalse);
    });

    // Un corps vide n'est pas une pièce : mis en cache, il se restituerait hors
    // ligne en PDF de zéro octet, avec toutes les apparences d'un succès.
    test('refuse un corps vide', () async {
      final cache = cacheWith();

      final entry = await cache.put(
        docType: 'RC',
        documentId: 'doc-1',
        schoolId: 'school-1',
        bytes: Uint8List(0),
      );

      expect(entry, isNull);
      expect(cacheDir.existsSync(), isFalse);
    });

    test('range le type sous sa forme canonique', () async {
      final cache = cacheWith();

      final entry = await putReceipt(cache, docType: 'rc');

      expect(entry!.docType, 'RC');
      expect(await cache.readByDocumentId('doc-1'), isNotNull);
    });

    // Le fichier porte la clé locale de la LIGNE. Réécrire une pièce déjà
    // connue sous une clé fraîche laisserait son ancien fichier derrière elle,
    // orphelin, pendant que la ligne continuerait de désigner l'ancien nom.
    test(
      'réécrire une pièce connue garde sa clé locale et son ancienneté',
      () async {
        final cache = cacheWith();
        await putReceipt(cache, marque: 'v1');

        clock = 2000;
        await putReceipt(cache, marque: 'v2');

        final entry = await EditiqueCacheDao(db).findByDocumentId('doc-1');
        expect(entry!.id, 'gen-1');
        expect(
          entry.createdAt,
          1000,
          reason: 'date de mise en cache conservée',
        );
        expect(entry.lastAccessedAt, 2000);
        expect(filesOnDisk(), ['gen-1.enc']);
        expect(await cache.readByDocumentId('doc-1'), equals(pdf('v2')));
      },
    );

    // Une pièce indexée par son seul numéro se voit compléter son identifiant
    // le jour où le serveur l'annonce (lot B2), sans changer de fichier.
    test('compléter l identifiant serveur ne déplace pas le fichier', () async {
      final cache = cacheWith();
      await cache.put(
        docType: 'RC',
        documentNumber: 'ETL-RC-2526-000001',
        schoolId: 'school-1',
        bytes: pdf('reçu'),
      );

      await putReceipt(cache);

      expect(filesOnDisk(), ['gen-1.enc']);
      expect(await cache.readByDocumentId('doc-1'), equals(pdf('reçu')));
    });

    test('un magasin en panne ne fait pas échouer l appelant', () async {
      final cache = cacheWith(
        cipher: (_) async => throw const EditiqueCipherException('disque'),
      );

      expect(await putReceipt(cache), isNull);
      expect(await EditiqueCacheDao(db).count(), 0);
    });

    // Le cas que l'écriture en deux temps existe pour empêcher : une mise en
    // cache refusée ne doit pas coûter la pièce déjà en cache. Hors ligne,
    // celle-ci ne se retélécharge pas.
    test(
      'un index qui refuse la ligne ne détruit pas la copie en place',
      () async {
        final cache = cacheWith();
        await putReceipt(
          cache,
          documentId: 'doc-1',
          documentNumber: 'N-1',
          marque: 'v1',
        );
        await putReceipt(cache, documentId: 'doc-2', documentNumber: 'N-2');
        expect(filesOnDisk(), ['gen-1.enc', 'gen-2.enc']);

        // Renuméroter doc-1 sur le numéro déjà pris par doc-2 : l'index unique
        // par école refuse.
        final entry = await cache.put(
          docType: 'RC',
          documentId: 'doc-1',
          documentNumber: 'N-2',
          schoolId: 'school-1',
          bytes: pdf('collision'),
        );

        expect(entry, isNull);
        expect(filesOnDisk(), ['gen-1.enc', 'gen-2.enc']);
        expect(await EditiqueCacheDao(db).count(), 2);
        expect(
          await cache.readByDocumentId('doc-1'),
          equals(pdf('v1')),
          reason: 'la pièce d hier survit au refus d aujourd hui',
        );
      },
    );
  });

  group('restitution', () {
    test('une pièce absente rend null', () async {
      final cache = cacheWith();

      expect(await cache.readByDocumentId('jamais-vue'), isNull);
      expect(
        await cache.readByDocumentNumber(
          schoolId: 'school-1',
          documentNumber: 'ETL-RC-0',
        ),
        isNull,
      );
    });

    // Sans cela, le cache évincerait par ancienneté de mise en cache : la pièce
    // qu'on ressort tous les jours serait la première à partir.
    test(
      'enregistre l accès, qui est la seule entrée du classement LRU',
      () async {
        final cache = cacheWith();
        await putReceipt(cache);

        clock = 7000;
        await cache.readByDocumentId('doc-1');

        final entry = await EditiqueCacheDao(db).findByDocumentId('doc-1');
        expect(entry!.lastAccessedAt, 7000);
      },
    );

    test('un fichier disparu se solde par un défaut de cache propre', () async {
      final cache = cacheWith();
      await putReceipt(cache);
      File(p.join(cacheDir.path, 'gen-1.enc')).deleteSync();

      expect(await cache.readByDocumentId('doc-1'), isNull);
      expect(
        await EditiqueCacheDao(db).count(),
        0,
        reason: 'la ligne suit son fichier, sinon elle ment au budget',
      );
    });

    test('un fichier corrompu est retiré du cache', () async {
      final cache = cacheWith();
      await putReceipt(cache);
      final file = File(p.join(cacheDir.path, 'gen-1.enc'));
      file.writeAsBytesSync(file.readAsBytesSync()..[30] ^= 0xFF);

      expect(await cache.readByDocumentId('doc-1'), isNull);
      expect(await EditiqueCacheDao(db).count(), 0);
      expect(filesOnDisk(), isEmpty);
    });

    // La distinction qui coûte des documents si on la rate : hors ligne, une
    // pièce détruite parce que le Keystore n'a pas répondu ne se retélécharge
    // pas. Le doute doit laisser la pièce en place.
    test('une panne passagère ne détruit ni le fichier ni la ligne', () async {
      await putReceipt(cacheWith());
      final cache = cacheWith(store: magasinRetif(lectureIndisponible: true));

      expect(await cache.readByDocumentId('doc-1'), isNull);

      expect(filesOnDisk(), ['gen-1.enc'], reason: 'les octets restent');
      expect(await EditiqueCacheDao(db).count(), 1, reason: 'la ligne reste');
      // Et la pièce redevient lisible dès que la panne cesse.
      expect(await cacheWith().readByDocumentId('doc-1'), isNotNull);
    });

    // Le classement LRU est une heuristique ; la pièce, elle, est déjà
    // déchiffrée et vérifiée en mémoire. La perdre parce que la base n'a pas
    // pris note de l'accès rendrait « indisponible » un document présent.
    test(
      'un accès qu on ne peut pas enregistrer ne perd pas la pièce',
      () async {
        final index = _DaoALaTraine(db);
        final cache = cacheWith(index: index);
        await putReceipt(cache);

        index.touchLeve = true;

        expect(await cache.readByDocumentId('doc-1'), equals(pdf('reçu')));
      },
    );

    // Fichier d'abord, ligne ensuite — et si le fichier résiste, la ligne
    // reste : elle est ce qui le compte au budget et le désignera à nouveau.
    test('un fichier qui refuse de partir garde sa ligne', () async {
      await putReceipt(cacheWith());
      File(p.join(cacheDir.path, 'gen-1.enc')).deleteSync();
      final cache = cacheWith(store: magasinRetif(effacementImpossible: true));

      expect(await cache.readByDocumentId('doc-1'), isNull);
      expect(await EditiqueCacheDao(db).count(), 1);
    });

    // Le sceau prouve que le fichier n'a pas bougé ; l'empreinte prouve que ce
    // sont les octets que la LIGNE décrit. Un arrêt entre l'écriture du fichier
    // et celle de la ligne produit exactement cet écart (RG-012-3).
    test('des octets valides mais étrangers à la ligne sont refusés', () async {
      final cache = cacheWith();
      await putReceipt(cache);
      await db.update(
        'editique_cache_entries',
        {'content_sha256': 'empreinte-d-une-autre-version'},
        where: 'id = ?',
        whereArgs: ['gen-1'],
      );

      expect(await cache.readByDocumentId('doc-1'), isNull);
      expect(filesOnDisk(), isEmpty);
      expect(await EditiqueCacheDao(db).count(), 0);
    });
  });

  group('éviction', () {
    // 3 pièces de ~313 octets pour un budget de 800 visant 90 % (720) : la
    // troisième écriture franchit le seuil, et le balayage part des moins
    // récemment LUES jusqu'à repasser sous la cible — donc une seule pièce.
    EditiqueDocumentCache petitBudget() => cacheWith(
      policy: const EditiqueCacheEvictionPolicy(
        budgetBytes: 800,
        targetRatio: 0.9,
      ),
    );

    test('balaie après l écriture qui franchit le budget', () async {
      final cache = petitBudget();

      await putReceipt(
        cache,
        documentId: 'a',
        documentNumber: 'N-a',
        taille: 300,
      );
      clock = 1100;
      await putReceipt(
        cache,
        documentId: 'b',
        documentNumber: 'N-b',
        taille: 300,
      );
      clock = 1200;
      await putReceipt(
        cache,
        documentId: 'c',
        documentNumber: 'N-c',
        taille: 300,
      );

      // La plus ancienne part, avec son fichier.
      expect(await cache.readByDocumentId('a'), isNull);
      expect(await cache.readByDocumentId('c'), isNotNull);
      expect(await EditiqueCacheDao(db).count(), 2);
      expect(filesOnDisk(), ['gen-2.enc', 'gen-3.enc']);
    });

    test('n évince rien tant que le budget tient', () async {
      final cache = petitBudget();

      await putReceipt(
        cache,
        documentId: 'a',
        documentNumber: 'N-a',
        taille: 100,
      );
      await putReceipt(
        cache,
        documentId: 'b',
        documentNumber: 'N-b',
        taille: 100,
      );

      expect(await EditiqueCacheDao(db).count(), 2);
      expect(filesOnDisk(), hasLength(2));
    });

    // Ce qui compte est la date de LECTURE, pas celle de mise en cache.
    test('épargne la pièce qu on ressort, pas la plus ancienne', () async {
      final cache = petitBudget();
      await putReceipt(
        cache,
        documentId: 'a',
        documentNumber: 'N-a',
        taille: 300,
      );
      clock = 1100;
      await putReceipt(
        cache,
        documentId: 'b',
        documentNumber: 'N-b',
        taille: 300,
      );

      clock = 1200;
      await cache.readByDocumentId('a');

      clock = 1300;
      await putReceipt(
        cache,
        documentId: 'c',
        documentNumber: 'N-c',
        taille: 300,
      );

      expect(await cache.readByDocumentId('a'), isNotNull);
      expect(await cache.readByDocumentId('b'), isNull);
    });

    test('sweepToBudget se rejoue seul, sans écriture', () async {
      final cache = petitBudget();
      await putReceipt(
        cache,
        documentId: 'a',
        documentNumber: 'N-a',
        taille: 300,
      );
      await putReceipt(
        cache,
        documentId: 'b',
        documentNumber: 'N-b',
        taille: 300,
      );

      expect(await cache.sweepToBudget(), 0);
    });
  });

  group('effacement', () {
    test('la réaffectation d école emporte les fichiers des autres', () async {
      final cache = cacheWith();
      await putReceipt(cache, documentId: 'a', documentNumber: 'N-a');
      await putReceipt(
        cache,
        documentId: 'b',
        documentNumber: 'N-b',
        schoolId: 'school-2',
      );

      final removed = await cache.purgeForeignSchools('school-1');

      expect(removed.map((e) => e.id), ['gen-2']);
      expect(filesOnDisk(), ['gen-1.enc']);
      expect(await cache.readByDocumentId('a'), isNotNull);
    });

    // L'inverse — les lignes d'abord — laisserait, si l'application s'arrête
    // entre les deux, des pièces d'un autre établissement sur le disque, que
    // plus aucune ligne ne désigne pour les réclamer. C'est ce que D-7
    // interdit.
    test('une réaffectation qui échoue garde ses lignes à reprendre', () async {
      await putReceipt(cacheWith(), documentId: 'a', documentNumber: 'N-a');
      await putReceipt(
        cacheWith(),
        documentId: 'b',
        documentNumber: 'N-b',
        schoolId: 'school-2',
      );
      final cache = cacheWith(store: magasinRetif(effacementImpossible: true));

      expect(await cache.purgeForeignSchools('school-1'), isEmpty);

      expect(await EditiqueCacheDao(db).count(), 2);
      expect(filesOnDisk(), ['gen-1.enc', 'gen-2.enc']);
      // Et une reprise, une fois le disque revenu, achève le travail.
      expect(await cacheWith().purgeForeignSchools('school-1'), hasLength(1));
      expect(filesOnDisk(), ['gen-1.enc']);
    });

    // « Aucune école courante » signifierait « toutes sont étrangères », donc
    // un cache vidé à chaque démarrage à froid — la DI offline est câblée avant
    // l'authentification.
    test('refuse de purger sans école courante', () async {
      final cache = cacheWith();
      await putReceipt(cache);

      expect(
        () => cache.purgeForeignSchools(''),
        throwsA(isA<ArgumentError>()),
      );
      expect(filesOnDisk(), ['gen-1.enc']);
    });

    test('purgeAll détruit les fichiers, la clé et l index', () async {
      final cache = cacheWith();
      await putReceipt(cache, documentId: 'a', documentNumber: 'N-a');
      await putReceipt(cache, documentId: 'b', documentNumber: 'N-b');

      expect(await cache.purgeAll(), 2);

      expect(await cacheDir.exists(), isFalse);
      expect(keys.destructions, 1);
      expect(await EditiqueCacheDao(db).count(), 0);
    });

    test('réclame les octets qu aucune ligne ne désigne plus', () async {
      final cache = cacheWith();
      await putReceipt(cache, documentId: 'a', documentNumber: 'N-a');
      await putReceipt(cache, documentId: 'b', documentNumber: 'N-b');
      // Une purge interrompue : les lignes sont parties, les fichiers non.
      await db.delete('editique_cache_entries');

      expect(await cache.reclaimOrphans(), 2);
      expect(filesOnDisk(), isEmpty);
    });

    test('la réclamation épargne ce que l index désigne encore', () async {
      final cache = cacheWith();
      await putReceipt(cache);

      expect(await cache.reclaimOrphans(), 0);
      expect(filesOnDisk(), ['gen-1.enc']);
    });
  });

  // Chaque pièce en vol coûte environ trois fois sa taille en mémoire, et deux
  // écritures simultanées de la MÊME pièce feraient décrire au fichier
  // survivant l'empreinte de l'autre — un défaut de cache permanent.
  group('une seule pièce à la fois', () {
    test('sérialise les écritures', () async {
      var enCours = 0;
      var maximum = 0;
      final cache = cacheWith(
        cipher: (request) async {
          enCours++;
          maximum = enCours > maximum ? enCours : maximum;
          await Future<void>.delayed(const Duration(milliseconds: 5));
          enCours--;
          return runEditiqueCipherTask(request);
        },
      );

      await Future.wait([
        putReceipt(cache, documentId: 'a', documentNumber: 'N-a'),
        putReceipt(cache, documentId: 'b', documentNumber: 'N-b'),
        putReceipt(cache, documentId: 'c', documentNumber: 'N-c'),
      ]);

      expect(maximum, 1);
      expect(await EditiqueCacheDao(db).count(), 3);
      expect(filesOnDisk(), hasLength(3));
    });

    test(
      'deux écritures concurrentes de la même pièce restent cohérentes',
      () async {
        final cache = cacheWith();

        await Future.wait([
          cache.put(
            docType: 'RC',
            documentId: 'doc-1',
            documentNumber: 'N-1',
            schoolId: 'school-1',
            bytes: pdf('v1'),
          ),
          cache.put(
            docType: 'RC',
            documentId: 'doc-1',
            documentNumber: 'N-1',
            schoolId: 'school-1',
            bytes: pdf('v2'),
          ),
        ]);

        expect(filesOnDisk(), ['gen-1.enc']);
        expect(await EditiqueCacheDao(db).count(), 1);
        // Peu importe laquelle des deux versions gagne : elle doit être lisible,
        // donc son empreinte doit être celle que la ligne annonce.
        expect(await cache.readByDocumentId('doc-1'), isNotNull);
      },
    );

    // La course que la revue a reproduite : une restitution qui tombe entre la
    // ligne (déjà à jour) et le fichier (pas encore publié) constate un écart
    // et voudrait tout détruire. Sous le verrou, elle refait son constat quand
    // l'écriture est finie — et sert la pièce au lieu de l'effacer.
    test(
      'une restitution prise au milieu d une réécriture ne détruit rien',
      () async {
        final index = _DaoALaTraine(db);
        final store = magasinRetif();
        final cache = cacheWith(index: index, store: store);
        await putReceipt(cache, marque: 'v1');

        final pause = Completer<void>();
        index.pause = pause;
        final reecriture = putReceipt(cache, marque: 'v2');

        // La ligne annonce v2, le fichier porte encore v1 : c'est l'instant que
        // la restitution doit traverser sans rien casser.
        await index.ligneEcrite.future;
        final restitution = cache.readByDocumentId('doc-1');
        await store.premiereLecture.future;

        pause.complete();
        index.pause = null;
        await reecriture;

        expect(await restitution, equals(pdf('v2')));
        expect(filesOnDisk(), ['gen-1.enc']);
        expect(await EditiqueCacheDao(db).count(), 1);
      },
    );

    // Une action qui lève ne doit pas condamner la file : le verrou libère son
    // tour même quand ce qu'il protégeait a échoué.
    test('une action qui lève ne bloque pas la file', () async {
      final cache = cacheWith();

      await expectLater(
        cache.purgeForeignSchools(''),
        throwsA(isA<ArgumentError>()),
      );

      expect(await putReceipt(cache), isNotNull);
    });

    test('une écriture qui échoue ne bloque pas la suivante', () async {
      var premiere = true;
      final cache = cacheWith(
        cipher: (request) async {
          if (premiere) {
            premiere = false;
            throw const EditiqueCipherException('panne');
          }
          return runEditiqueCipherTask(request);
        },
      );

      expect(
        await putReceipt(cache, documentId: 'a', documentNumber: 'N-a'),
        isNull,
      );
      await putReceipt(cache, documentId: 'b', documentNumber: 'N-b');

      expect(await cache.readByDocumentId('b'), isNotNull);
    });
  });
}
